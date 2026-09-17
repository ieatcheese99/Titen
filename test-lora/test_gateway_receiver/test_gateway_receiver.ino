/**
 * ====================================================================================
 * PROJECT TITEN - TEST LORA RECEIVER (GATEWAY LISTENER)
 * File: test_gateway_receiver.ino
 * Target Board: ESP32-S3 DevKitC-1 N16R8 / ESP32 Classic (ESP-WROOM-32)
 * Deskripsi: Program uji coba penerima radio LoRa RA-02 SX1278 (Gateway).
 *            Menerima paket, menampilkan isi pesan string, RSSI (kekuatan sinyal),
 *            dan SNR (Signal-to-Noise Ratio).
 * ====================================================================================
 */

#include <Arduino.h>
#include <SPI.h>
#include <LoRa.h>

// ====================================================================================
// PILIH TIPE BOARD (Buka komentar salah satu yang sesuai):
// ====================================================================================
#define BOARD_ESP32_S3       // Gunakan ini jika Gateway menggunakan ESP32-S3
// #define BOARD_ESP32_CLASSIC  // Buka komentar ini jika Gateway menggunakan ESP32 WROOM-32

#if defined(BOARD_ESP32_S3)
    // Pinout SPI Hardware LoRa RA-02 untuk ESP32-S3
    #define PIN_LORA_SCK     12
    #define PIN_LORA_MISO    13
    #define PIN_LORA_MOSI    11
    #define PIN_LORA_CS      10
    #define PIN_LORA_RST     14
    #define PIN_LORA_DIO0    21
#elif defined(BOARD_ESP32_CLASSIC)
    // Pinout SPI Hardware LoRa RA-02 untuk ESP32 WROOM-32
    #define PIN_LORA_SCK     18
    #define PIN_LORA_MISO    19
    #define PIN_LORA_MOSI    23
    #define PIN_LORA_CS      5
    #define PIN_LORA_RST     14
    #define PIN_LORA_DIO0    2
#else
    #error "Harap pilih tipe board: BOARD_ESP32_S3 atau BOARD_ESP32_CLASSIC!"
#endif

// ====================================================================================
// PARAMETER FREKUENSI & RADIO LORA (Wajib sama persis dengan Node Transmitter)
// ====================================================================================
#define LORA_FREQUENCY       433E6       // 433 MHz
#define LORA_SPREAD_FACTOR   10          // SF10
#define LORA_BANDWIDTH       125E3       // 125 kHz
#define LORA_CODING_RATE     5           // 4/5

uint32_t totalPacketsReceived = 0;

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println("\n==================================================");
    Serial.println("   TITEN - UJI COBA RECEIVER LORA (GATEWAY)       ");
    Serial.println("==================================================");

#if defined(BOARD_ESP32_S3)
    Serial.println("[INFO] Board: ESP32-S3 (SCK:12, MISO:13, MOSI:11, CS:10, RST:14, DIO0:21)");
#else
    Serial.println("[INFO] Board: ESP32 WROOM-32 (SCK:18, MISO:19, MOSI:23, CS:5, RST:14, DIO0:2)");
#endif

    // Inisialisasi Bus SPI khusus pin yang ditentukan
    SPI.begin(PIN_LORA_SCK, PIN_LORA_MISO, PIN_LORA_MOSI, PIN_LORA_CS);
    LoRa.setPins(PIN_LORA_CS, PIN_LORA_RST, PIN_LORA_DIO0);

    Serial.print("[INFO] Menginisialisasi Modul LoRa RA-02 di 433 MHz... ");
    if (!LoRa.begin(LORA_FREQUENCY)) {
        Serial.println("\n[ERROR] Modul LoRa gagal terdeteksi!");
        Serial.println("Periksa wiring:");
        Serial.println("  1. Pastikan VCC terhubung ke 3.3V (Bukan 5V!)");
        Serial.println("  2. Pastikan pin SPI (SCK, MISO, MOSI, CS/NSS) terpasang benar");
        Serial.println("  3. Pastikan GND tersambung sempurna");
        while (1) {
            delay(1000);
        }
    }

    // Konfigurasi parameter radio harus identik dengan sender
    LoRa.setSpreadingFactor(LORA_SPREAD_FACTOR);
    LoRa.setSignalBandwidth(LORA_BANDWIDTH);
    LoRa.setCodingRate4(LORA_CODING_RATE);

    Serial.println("BERHASIL!");
    Serial.println("[OK] Gateway standby mendengarkan paket masuk dari Node...\n");
}

void loop() {
    // Periksa apakah ada paket radio yang tertangkap
    int packetSize = LoRa.parsePacket();
    if (packetSize) {
        totalPacketsReceived++;

        String incoming = "";
        while (LoRa.available()) {
            incoming += (char)LoRa.read();
        }

        int rssi = LoRa.packetRssi();
        float snr = LoRa.packetSnr();

        Serial.printf("[RX #%u] Pesan: '%s' | Ukuran: %d Bytes | RSSI: %d dBm | SNR: %.2f dB\n",
                      totalPacketsReceived,
                      incoming.c_str(),
                      packetSize,
                      rssi,
                      snr);

        // Evaluasi Kualitas Sinyal
        if (rssi > -90) {
            Serial.println("       --> Kualitas Sinyal: SANGAT KUAT (Excellent)");
        } else if (rssi > -110) {
            Serial.println("       --> Kualitas Sinyal: CUKUP BAIK (Good)");
        } else {
            Serial.println("       --> Kualitas Sinyal: LEMAH (Weak, dekat batas jangkauan)");
        }
    }
}
