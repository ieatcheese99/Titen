/**
 * ====================================================================================
 * PROJECT TITEN - SISTEM PERINGATAN DINI BENCANA LONGSOR & KARHUTLA (MAGE 12)
 * File: gateway_node.ino
 * Target Board: ESP32 / ESP32-S3 LoRa Gateway Node
 * Fungsi: Menerima paket LoRa 16-Byte dari Node Lereng -> Cek CRC16 -> Teruskan via WiFi / Serial JSON
 * Tim: TRILOGY - SMK Budi Luhur
 * ====================================================================================
 */

#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>
#include <WiFi.h>

// ======================= PIN LoRa GATEWAY =======================
// Sesuaikan dengan board gateway yang digunakan (contoh ESP32-S3 atau ESP32 Classic)
#define LORA_SCK             12
#define LORA_MISO            13
#define LORA_MOSI            11
#define LORA_CS              10
#define LORA_RST             14
#define LORA_DIO0            21

#define LORA_BAND            433E6       // 433 MHz (sama persis dengan Node)
#define LORA_SPREAD_FACTOR   10
#define LORA_BANDWIDTH       125E3

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

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n[TITEN] Memulai LoRa Gateway...");

    // Setup SPI & LoRa
    SPI.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);
    LoRa.setPins(LORA_CS, LORA_RST, LORA_DIO0);

    if (!LoRa.begin(LORA_BAND)) {
        Serial.println("[ERR] LoRa Gateway gagal dimulai!");
        while (1);
    }

    LoRa.setSpreadingFactor(LORA_SPREAD_FACTOR);
    LoRa.setSignalBandwidth(LORA_BANDWIDTH);
    Serial.printf("[OK] Gateway siap mendengarkan sinyal di frekuensi %.1f MHz...\n", LORA_BAND / 1E6);
}

void loop() {
    int packetSize = LoRa.parsePacket();
    if (packetSize == sizeof(TitenPayload)) {
        TitenPayload rxPayload;
        LoRa.readBytes((uint8_t*)&rxPayload, sizeof(TitenPayload));

        // Verifikasi Checksum CRC16
        uint16_t calculatedCRC = computeCRC16((uint8_t*)&rxPayload, sizeof(TitenPayload) - sizeof(uint16_t));
        if (calculatedCRC != rxPayload.checksum) {
            Serial.println("[WARN] Paket diterima tetapi Checksum CRC16 Rusak/Corrupt!");
            return;
        }

        int rssi = LoRa.packetRssi();
        float snr = LoRa.packetSnr();

        // Print format JSON ke Serial agar mudah dihubungkan ke backend, dashboard, atau Python gateway
        Serial.printf("{\"node_id\":%d,\"battery_pct\":%d,\"tilt_deg\":%.1f,\"soil_moisture\":%d,\"air_temp\":%.1f,\"air_humidity\":%d,\"hazard_type\":%d,\"status_level\":%d,\"rssi\":%d,\"snr\":%.1f}\n",
                      rxPayload.node_id,
                      rxPayload.battery_pct,
                      rxPayload.tilt_x10 / 10.0f,
                      rxPayload.soil_moisture,
                      rxPayload.air_temp_x10 / 10.0f,
                      rxPayload.air_humidity,
                      rxPayload.hazard_type,
                      rxPayload.status_level,
                      rssi,
                      snr);

        // Jika status AWAS (status_level == 3), trigger peringatan darurat seketika
        if (rxPayload.status_level >= 2) {
            Serial.println(">>> [EMERGENCY ALERT BROADCAST TO CLOUD & MOBILE APP] <<<");
        }
    }
}
