# Panduan Flashing Firmware & Pengaturan Hardware TITEN

Dokumentasi ini dibuat khusus untuk memprogram board **ESP32-S3 DevKitC-1 N16R8 (16MB Flash, 8MB PSRAM)** dan **LoRa RA-02 SX1278 (433MHz)** sesuai proposal dan PRD MAGE 12.

---

## 1. Persiapan Arduino IDE

### A. Install Board ESP32
1. Buka Arduino IDE -> Masuk ke **File** > **Preferences**.
2. Pada kolom *Additional boards manager URLs*, tambahkan URL resmi Espressif:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Buka **Tools** > **Board** > **Boards Manager**, cari `esp32` by Espressif Systems, lalu klik **Install** (pilih versi 2.0.11 atau yang lebih baru).

### B. Library yang Wajib Diinstall (via Library Manager)
Buka **Sketch** > **Include Library** > **Manage Libraries**, lalu cari dan install:
1. `LoRa` oleh **Sandeep Mistry**
2. `Adafruit MPU6050` oleh **Adafruit**
3. `Adafruit Unified Sensor` oleh **Adafruit**
4. `DHT sensor library` oleh **Adafruit**

---

## 2. Pengaturan Board Arduino IDE (PENTING UNTUK ESP32-S3 N16R8)

Sebelum melakukan klik **Upload / Flash**, pastikan menu **Tools** diatur seperti berikut:

* **Board**: `ESP32S3 Dev Module`
* **USB CDC On Boot**: `Enabled` *(Sangat krusial! Jika Disabled, Serial Monitor via port Type-C tidak akan muncul)*
* **Flash Size**: `16MB (128Mb)` *(Sesuai spesifikasi N16R8)*
* **Partition Scheme**: `16M Flash (3MB APP/9.9MB FATFS)` atau `Default 4MB with spiffs`
* **PSRAM**: `OPI PSRAM` *(Sesuai varian N16R8 yang memiliki 8MB Octal PSRAM)*
* **Upload Mode**: `UART0 / Hardware CDC`
* **Port**: Pilih port COM ESP32-S3 yang terdeteksi

---

## 3. Rangkuman Pinout Cepat (Wiring Cheat-Sheet)

| Komponen | Pin Modul | Sambungkan ke ESP32-S3 |
| :--- | :--- | :--- |
| **MPU-6050** | SDA / SCL | **GPIO 8 / GPIO 9** |
| | INT | **GPIO 4** |
| | VCC / GND | 3.3V / GND |
| **Capacitive Soil** | AOUT | **GPIO 1** |
| | VCC / GND | 3.3V / GND |
| **DHT22** | DATA | **GPIO 2** |
| | VCC / GND | 3.3V / GND |
| **KY-026 Flame** | DO | **GPIO 3** |
| | VCC / GND | 3.3V / GND |
| **Battery Divider** | S | **GPIO 5** |
| | VCC / GND | Baterai (+) / GND |
| **Relay Sirine/LED** | IN | **GPIO 6** |
| | VCC / GND | 3.3V (atau 5V) / GND |
| **LoRa RA-02** | SCK / MISO / MOSI | **GPIO 12 / GPIO 13 / GPIO 11** |
| | CS (NSS) / RST / DIO0 | **GPIO 10 / GPIO 14 / GPIO 21** |
| | VCC / GND | **3.3V (Wajib!)** / GND |
