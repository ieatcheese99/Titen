/**
 * ====================================================================================
 * PROJECT TITEN - SISTEM PERINGATAN DINI BENCANA LONGSOR & KARHUTLA (MAGE 12)
 * File: gateway_node.ino
 * Target Board: ESP32 / ESP32-S3 LoRa Gateway Node
 * Fungsi: Menerima paket LoRa 16-Byte -> Cek CRC16 -> LCD dan Serial JSON
 * Tim: TRILOGY - SMK Budi Luhur
 * ====================================================================================
 */

#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// ======================= PROFIL BOARD GATEWAY =======================
// Pilihan board Arduino menentukan pin. Gateway fisik proyek: ESP32 WROOM-32.
#if defined(CONFIG_IDF_TARGET_ESP32)
#define GATEWAY_BOARD_NAME   "ESP32 WROOM-32"
#define LORA_SCK             18
#define LORA_MISO            19
#define LORA_MOSI            23
#define LORA_CS              5
#define LORA_RST             14
#define LORA_DIO0            26
#define PIN_I2C_SDA          21
#define PIN_I2C_SCL          22
#elif defined(CONFIG_IDF_TARGET_ESP32S3)
#define GATEWAY_BOARD_NAME   "ESP32-S3"
#define LORA_SCK             12
#define LORA_MISO            13
#define LORA_MOSI            11
#define LORA_CS              10
#define LORA_RST             14
#define LORA_DIO0            21
#define PIN_I2C_SDA          8
#define PIN_I2C_SCL          9
#else
#error "Gateway TITEN hanya mendukung ESP32 WROOM-32 atau ESP32-S3. Pilih board yang sesuai."
#endif

#define LORA_BAND            433E6       // 433 MHz (sama persis dengan Node)
#define LORA_SPREAD_FACTOR   10
#define LORA_BANDWIDTH       125E3

// ======================= PIN & KONFIGURASI LCD I2C =======================
// Menggunakan modul LCD 16x2 atau 20x4 dengan I2C Backpack (PCF8574)
#define LCD_I2C_ADDR         0x27        // Alamat umum: 0x27 atau 0x3F (cek I2C scanner jika tidak tampil)
#define LCD_COLS             16          // Jumlah kolom LCD (16 karakter)
#define LCD_ROWS             2           // Jumlah baris LCD (2 baris)

// Inisialisasi Objek LCD
LiquidCrystal_I2C lcd(LCD_I2C_ADDR, LCD_COLS, LCD_ROWS);

// ======================= STRUCT BINARY 16-BYTE =======================
typedef struct __attribute__((__packed__)) {
    uint8_t  node_id;         // 1 Byte
    uint8_t  battery_pct;     // 1 Byte
    int16_t  tilt_x10;        // 2 Byte
    uint8_t  soil_moisture;   // 1 Byte
    int16_t  air_temp_x10;    // 2 Byte
    uint8_t  air_humidity;    // 1 Byte
    uint8_t  hazard_type;     // 1 Byte: 0: Normal, 1: Longsor, 2: Karhutla
    uint8_t  status_level;    // 1 Byte: 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
    uint32_t timestamp_rtc;   // 4 Byte
    uint16_t checksum;        // 2 Byte
} TitenPayload;

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

// Fungsi string representasi status bahaya
const char* getStatusName(uint8_t status) {
    switch (status) {
        case 0: return "AMAN";
        case 1: return "WASPADA";
        case 2: return "SIAGA";
        case 3: return "AWAS";
        default: return "UNKNOWN";
    }
}

void updateLcdStandby() {
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("TITEN GATEWAY OK");
    lcd.setCursor(0, 1);
    lcd.print("Menunggu Node...");
}

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n[TITEN] Memulai LoRa Gateway...");
    Serial.printf("[BOARD] %s | LoRa SCK=%d MISO=%d MOSI=%d CS=%d RST=%d DIO0=%d | LCD SDA=%d SCL=%d\n",
                  GATEWAY_BOARD_NAME, LORA_SCK, LORA_MISO, LORA_MOSI,
                  LORA_CS, LORA_RST, LORA_DIO0, PIN_I2C_SDA, PIN_I2C_SCL);

    // 1. Inisialisasi Bus I2C & LCD Display
    Wire.begin(PIN_I2C_SDA, PIN_I2C_SCL);
    lcd.init();
    lcd.backlight();
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print(" TITEN  GATEWAY ");
    lcd.setCursor(0, 1);
    lcd.print("Inisialisasi...");

    delay(1000);

    // 2. Setup SPI & LoRa SX1278
    SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
    LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);

    if (!LoRa.begin(LORA_BAND)) {
        Serial.println("[ERR] LoRa Gateway gagal dimulai!");
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("LoRa INIT ERROR!");
        lcd.setCursor(0, 1);
        lcd.print("Cek Kabel SPI...");
        while (1) {
            delay(1000);
        }
    }

    LoRa.setSpreadingFactor(LORA_SPREAD_FACTOR);
    LoRa.setSignalBandwidth(LORA_BANDWIDTH);
    Serial.printf("[OK] Gateway siap mendengarkan sinyal di frekuensi %.1f MHz...\n", LORA_BAND / 1E6);

    // Tampilkan status standby di LCD
    updateLcdStandby();
}

void loop() {
    int packetSize = LoRa.parsePacket();
    if (packetSize > 0) {
        if (packetSize == sizeof(TitenPayload)) {
            TitenPayload rxPayload;
            LoRa.readBytes((uint8_t*)&rxPayload, sizeof(TitenPayload));

            // Verifikasi Checksum CRC16
            uint16_t calculatedCRC = computeCRC16((uint8_t*)&rxPayload, sizeof(TitenPayload) - sizeof(uint16_t));
            if (calculatedCRC != rxPayload.checksum) {
                Serial.println("[WARN] Paket diterima tetapi Checksum CRC16 Rusak/Corrupt!");
                lcd.clear();
                lcd.setCursor(0, 0);
                lcd.print("PAKET ERROR CRC!");
                lcd.setCursor(0, 1);
                lcd.print("Checksum Corrupt");
                return;
            }

            int rssi = LoRa.packetRssi();
            float snr = LoRa.packetSnr();
            float tiltVal = rxPayload.tilt_x10 / 10.0f;
            float tempVal = rxPayload.air_temp_x10 / 10.0f;

            // Print format JSON ke Serial agar mudah dihubungkan ke backend, dashboard, atau Python gateway
            Serial.printf("{\"node_id\":%d,\"battery_pct\":%d,\"tilt_deg\":%.1f,\"soil_moisture\":%d,\"air_temp\":%.1f,\"air_humidity\":%d,\"hazard_type\":%d,\"status_level\":%d,\"rssi\":%d,\"snr\":%.1f}\n",
                          rxPayload.node_id,
                          rxPayload.battery_pct,
                          tiltVal,
                          rxPayload.soil_moisture,
                          tempVal,
                          rxPayload.air_humidity,
                          rxPayload.hazard_type,
                          rxPayload.status_level,
                          rssi,
                          snr);

            // ================= TAMPILKAN PADA LCD 16x2 =================
            lcd.clear();

            if (rxPayload.status_level >= 2) {
                // Tampilan Darurat / Bahaya (SIAGA atau AWAS)
                lcd.setCursor(0, 0);
                if (rxPayload.status_level == 3) {
                    lcd.print("!AWAS! N");
                } else {
                    lcd.print("!SIAGA! N");
                }
                lcd.print(rxPayload.node_id);
                lcd.print(rxPayload.hazard_type == 1 ? " LONGSOR" : (rxPayload.hazard_type == 2 ? " KARHUTLA" : " BAHAYA"));

                lcd.setCursor(0, 1);
                if (rxPayload.hazard_type == 1) {
                    // Tampilkan Kemiringan & Kelembapan Tanah
                    char line2[17];
                    snprintf(line2, sizeof(line2), "Tlt:%.1f S:%d%%", tiltVal, rxPayload.soil_moisture);
                    lcd.print(line2);
                } else {
                    // Tampilkan Suhu & Kelembapan Udara
                    char line2[17];
                    snprintf(line2, sizeof(line2), "T:%.1fC H:%d%%", tempVal, rxPayload.air_humidity);
                    lcd.print(line2);
                }

                Serial.println(">>> [EMERGENCY ALERT BROADCAST TO CLOUD & MOBILE APP] <<<");
            } else {
                // Tampilan Normal / Telemetri Rutin (AMAN / WASPADA)
                // Baris 1: ID Node, Status, dan RSSI sinyal
                // Contoh: "N01 AMAN -75dBm"
                char line1[17];
                snprintf(line1, sizeof(line1), "N%02d %-7s %ddB",
                         rxPayload.node_id,
                         getStatusName(rxPayload.status_level),
                         rssi);
                lcd.setCursor(0, 0);
                lcd.print(line1);

                // Baris 2: Data Sensor (Suhu, Tanah, Baterai)
                // Contoh: "28C S:65% B:98%"
                char line2[17];
                snprintf(line2, sizeof(line2), "%.0fC S:%d%% B:%d%%",
                         tempVal,
                         rxPayload.soil_moisture,
                         rxPayload.battery_pct);
                lcd.setCursor(0, 1);
                lcd.print(line2);
            }
        } else {
            // Bersihkan buffer jika ukuran paket radio tidak sesuai (noise atau anomali)
            Serial.printf("[WARN] Paket diabaikan, ukuran: %d bytes (harus %d bytes)\n", packetSize, (int)sizeof(TitenPayload));
            while (LoRa.available()) {
                LoRa.read();
            }
        }
    }
}
