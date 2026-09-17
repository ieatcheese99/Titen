/**
 * ====================================================================================
 * PROJECT TITEN - SISTEM PERINGATAN DINI BENCANA LONGSOR & KARHUTLA (MAGE 12)
 * File: node_sensor.ino
 * Target Board: ESP32-S3 DevKitC-1 N16R8 (16MB Flash, 8MB PSRAM)
 * Standar Acuan: PRD TITEN v2.1.0 (Section 6, 7, 8) & Proposal MAGE 12
 * Tim: TRILOGY - SMK Budi Luhur
 * ====================================================================================
 */

#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <DHT.h>
#include "esp_sleep.h"

// ======================= DEFINISI PINOUT ESP32-S3 =======================
// Catatan: Pin GPIO 26-32 dilarang digunakan karena dipakai internal SPI Flash/PSRAM

// 1. I2C Bus untuk MPU-6050 (Kemiringan tebing & akselerasi)
#define PIN_I2C_SDA          8
#define PIN_I2C_SCL          9
#define PIN_MPU_INT          GPIO_NUM_4  // RTC GPIO untuk Wake-on-Threshold interrupt

// 2. Sensor Lingkungan & Bencana
#define PIN_SOIL_ADC         1           // ADC1_CH0 untuk Capacitive Soil Moisture V2
#define PIN_DHT22_DATA       2           // Single-bus data DHT22 (Suhu & Kelembapan Udara)
#define PIN_FLAME_DO         3           // KY-026 Flame Sensor (Digital Active LOW)
#define PIN_BATTERY_ADC      5           // ADC1_CH4 via Voltage Divider 5:1 (Tegangan Baterai)
#define PIN_RELAY_ALARM      6           // Relay 3.3V memicu Sirine 120dB & LED Strobe 3V

// 3. SPI Bus untuk Modul LoRa RA-02 SX1278
#define PIN_LORA_SCK         12
#define PIN_LORA_MISO        13
#define PIN_LORA_MOSI        11
#define PIN_LORA_CS          10
#define PIN_LORA_RST         14
#define PIN_LORA_DIO0        21

// ======================= KONFIGURASI OPERASIONAL =======================
#define NODE_ID              1           // ID Unik Node (1 s.d 255)
#define LORA_BAND            433E6       // 433 MHz sesuai modul RA-02 Tokopedia (atau 915E6)
#define LORA_TX_POWER        20          // 20 dBm (Daya pancar maksimal tembus lereng/hutan)
#define LORA_SPREAD_FACTOR   10          // SF10: Keseimbangan optimal jangkauan vs durasi transmisi
#define LORA_BANDWIDTH       125E3

// Manajemen Daya Deep Sleep SoPoWake
#define SLEEP_DURATION_SEC   21600       // 6 Jam rutin lapor status "AMAN" (6 * 3600 dtk)
#define uS_TO_S_FACTOR       1000000ULL  // Konversi mikrodetik ke detik

#define DHT_TYPE             DHT22

// Threshold Bencana Sesuai PRD Section 4 (FR-1.4)
#define THRESHOLD_TILT_DEG   5.0f        // Kemiringan lereng > 5.0 derajat
#define THRESHOLD_SOIL_WET   80          // Kelembapan tanah > 80% (jenuh air hujan)
#define THRESHOLD_TEMP_FIRE  45.0f       // Suhu udara > 45.0 °C
#define THRESHOLD_HUM_DRY    25          // Kelembapan udara < 25% (kering ekstrem)

// Kalibrasi ADC Capacitive Soil Moisture (12-bit ADC: 0 - 4095)
#define SOIL_ADC_DRY_AIR     3100        // Nilai saat probe di udara bebas (0%)
#define SOIL_ADC_WET_WATER   1300        // Nilai saat probe tercelup air basah (100%)

// ======================= STRUCT BINARY 16-BYTE SESUAI PRD =======================
typedef struct __attribute__((__packed__)) {
    uint8_t  node_id;         // 1 Byte: ID Node Sensor (1-255)
    uint8_t  battery_pct;     // 1 Byte: Sisa Baterai (0-100%)
    int16_t  tilt_x10;        // 2 Byte: Sudut Kemiringan x 10 (misal: 14.5 deg -> 145)
    uint8_t  soil_moisture;   // 1 Byte: Kelembapan Tanah (0-100%)
    int16_t  air_temp_x10;    // 2 Byte: Suhu Udara DHT22 x 10 (misal: 48.2 C -> 482)
    uint8_t  air_humidity;    // 1 Byte: Kelembapan Udara DHT22 (0-100%)
    uint8_t  hazard_type;     // 1 Byte: 0: Normal, 1: Longsor, 2: Karhutla
    uint8_t  status_level;    // 1 Byte: 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
    uint32_t timestamp_rtc;   // 4 Byte: Unix Timestamp RTC
    uint16_t checksum;        // 2 Byte: CRC16 Checksum Data
} TitenPayload;               // Total Persis 16 Bytes

// ======================= INSTANSIASI OBJEK =======================
Adafruit_MPU6050 mpu;
DHT dht(PIN_DHT22_DATA, DHT_TYPE);

// ======================= FUNGSI UTILITAS =======================
// Perhitungan CRC16 Modbus/IBM untuk integritas transmisi radio
uint16_t computeCRC16(const uint8_t *data, size_t len) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < len; i++) {
        crc ^= (uint16_t)data[i];
        for (uint8_t j = 0; j < 8; j++) {
            if (crc & 0x0001) {
                crc = (crc >> 1) ^ 0xA001;
            } else {
                crc = crc >> 1;
            }
        }
    }
    return crc;
}

// Membaca persentase baterai 18650 (3.0V - 4.2V) via pembagi tegangan 5:1
uint8_t readBatteryLevel() {
    int raw = analogRead(PIN_BATTERY_ADC);
    float vAdc = (raw / 4095.0f) * 3.3f;
    float vBat = vAdc * 5.0f; // Rasio resistor divider

    if (vBat >= 4.2f) return 100;
    if (vBat <= 3.0f) return 0;
    return (uint8_t)(((vBat - 3.0f) / 1.2f) * 100.0f);
}

// Membaca kelembapan tanah kapasitif terkalibrasi (0 - 100%)
uint8_t readSoilPercentage() {
    int raw = analogRead(PIN_SOIL_ADC);
    int mapped = map(raw, SOIL_ADC_DRY_AIR, SOIL_ADC_WET_WATER, 0, 100);
    return (uint8_t)constrain(mapped, 0, 100);
}

// ======================= SETUP PROGRAM =======================
void setup() {
    Serial.begin(115200);
    delay(400); // Waktu stabilisasi regulator tegangan
    Serial.println("\n==========================================");
    Serial.println("  TITEN EDGE SENSOR NODE (MAGE 12 - ITS)  ");
    Serial.println("==========================================");

    // Konfigurasi Pin Aktuator & Sensor
    pinMode(PIN_RELAY_ALARM, OUTPUT);
    digitalWrite(PIN_RELAY_ALARM, LOW); // Default mati
    pinMode(PIN_FLAME_DO, INPUT);

    // 1. Inisialisasi I2C MPU6050
    Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
    if (!mpu.begin(0x68, &Wire)) {
        Serial.println("[ERR] MPU-6050 tidak terdeteksi pada bus I2C!");
    } else {
        mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
        mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);
        Serial.println("[OK] MPU-6050 Accelerometer Siap.");
    }

    // 2. Inisialisasi DHT22
    dht.begin();
    Serial.println("[OK] DHT22 Temp/Humidity Siap.");

    // 3. Inisialisasi LoRa SX1278
    SPI.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_CS);
    LoRa.setPins(PIN_LORA_CS, PIN_LORA_RST, PIN_LORA_DIO0);
    if (!LoRa.begin(LORA_BAND)) {
        Serial.println("[ERR] LoRa SX1278 gagal inisialisasi!");
    } else {
        LoRa.setTxPower(LORA_TX_POWER);
        LoRa.setSpreadingFactor(LORA_SPREAD_FACTOR);
        LoRa.setSignalBandwidth(LORA_BANDWIDTH);
        Serial.printf("[OK] LoRa SX1278 Berhasil Aktif di %.1f MHz.\n", LORA_BAND / 1E6);
    }

    // ================= SAMPLING SENSOR =================
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // Hitung kemiringan lereng (Tilt Pitch Angle) berbasis proyeksi gravitasi bumi
    float pitchDeg = atan2(a.acceleration.y, sqrt(a.acceleration.x * a.acceleration.x + a.acceleration.z * a.acceleration.z)) * 180.0 / PI;
    float currentTilt = fabs(pitchDeg);

    // Baca Suhu & Kelembapan Udara
    float airTemp = dht.readTemperature();
    float airHum = dht.readHumidity();
    if (isnan(airTemp)) airTemp = 27.5f; // Nilai fallback jika sensor disconnected
    if (isnan(airHum)) airHum = 65.0f;

    // Baca Kelembapan Tanah, Baterai, & Sensor Api
    uint8_t soilMoist = readSoilPercentage();
    uint8_t batLevel = readBatteryLevel();
    bool flameDetected = (digitalRead(PIN_FLAME_DO) == LOW); // Sensor KY-026 Active LOW

    Serial.printf("[TELEMETRI] Tilt: %.1f deg | Tanah: %d%% | Suhu: %.1f C | Hum: %.0f%% | Bat: %d%%\n",
                  currentTilt, soilMoist, airTemp, airHum, batLevel);

    // ================= DUAL HAZARD DECISION ENGINE (PRD Section 4) =================
    uint8_t hazardType = 0;   // 0: Normal, 1: Longsor, 2: Karhutla
    uint8_t statusLevel = 0;  // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas

    // Cabang 1: Analisis Bahaya Tanah Longsor
    if (currentTilt > THRESHOLD_TILT_DEG && soilMoist > THRESHOLD_SOIL_WET) {
        hazardType = 1;
        statusLevel = 3; // AWAS LONGSOR
    } else if (currentTilt > THRESHOLD_TILT_DEG || soilMoist > 70) {
        hazardType = 1;
        statusLevel = 1; // WASPADA LONGSOR
    }

    // Cabang 2: Analisis Bahaya Karhutla
    if ((airTemp > THRESHOLD_TEMP_FIRE && airHum < THRESHOLD_HUM_DRY) || flameDetected) {
        hazardType = 2;
        statusLevel = 3; // AWAS KARHUTLA
    } else if (airTemp > 40.0f || airHum < 30) {
        if (hazardType == 0) {
            hazardType = 2;
            statusLevel = 1; // WASPADA KARHUTLA
        }
    }

    // ================= EKSEKUSI ALARM LOKAL (BUZZER + LED) =================
    if (statusLevel >= 2) {
        // Bahaya Siaga atau Awas: Buzzer 120dB dan LED Strobe menyala instan (< 500ms)
        digitalWrite(PIN_RELAY_ALARM, HIGH);
        Serial.printf("[ALARM AKTIF] Status Level: %d | Bahaya: %s\n", 
                      statusLevel, (hazardType == 1 ? "LONGSOR" : "KARHUTLA"));
    } else {
        digitalWrite(PIN_RELAY_ALARM, LOW);
    }

    // ================= MERAKIT PACKET BINARY 16-BYTE =================
    TitenPayload payload;
    payload.node_id       = NODE_ID;
    payload.battery_pct   = batLevel;
    payload.tilt_x10      = (int16_t)(currentTilt * 10.0f);
    payload.soil_moisture = soilMoist;
    payload.air_temp_x10  = (int16_t)(airTemp * 10.0f);
    payload.air_humidity  = (uint8_t)airHum;
    payload.hazard_type   = hazardType;
    payload.status_level  = statusLevel;
    payload.timestamp_rtc = (uint32_t)(millis() / 1000);
    payload.checksum      = 0;

    // Hitung CRC16 dari 14 byte pertama payload
    payload.checksum = computeCRC16((uint8_t*)&payload, sizeof(TitenPayload) - sizeof(uint16_t));

    // Kirim Paket via Radio LoRa
    LoRa.beginPacket();
    LoRa.write((uint8_t*)&payload, sizeof(TitenPayload));
    LoRa.endPacket();
    Serial.println("[LoRa] Paket 16-Byte Berhasil Dipancarkan.");

    // Durasi bunyi alarm lokal sebelum modul tidur kembali
    if (statusLevel >= 2) {
        delay(10000); // Sirine berbunyi 10 detik
        digitalWrite(PIN_RELAY_ALARM, LOW);
    }

    // ================= MANAJEMEN DAYA SOPOWAKE DEEP SLEEP =================
    Serial.println("[POWER] Masuk ke Mode Deep Sleep ultra-hemat daya...");
    LoRa.sleep();

    // 1. Timer rutin bangun setiap 6 jam
    esp_sleep_enable_timer_wakeup(SLEEP_DURATION_SEC * uS_TO_S_FACTOR);

    // 2. Motion interrupt MPU-6050 (Wake-on-Threshold getaran/kemiringan seketika)
    #if SOC_PM_SUPPORT_EXT0_WAKEUP
    esp_sleep_enable_ext0_wakeup(PIN_MPU_INT, 1);
    #endif

    esp_deep_sleep_start();
}

void loop() {
    // Kosong: ESP32 beroperasi dengan siklus Deep Sleep -> Wake -> Transmit -> Sleep
}
