# Panduan Flashing Firmware & Pengaturan Hardware TITEN

Node memakai **ESP32-S3 DevKitC-1 N16R8 (16MB Flash, 8MB PSRAM)**. Gateway fisik yang dikonfirmasi memakai **ESP32 WROOM-32 biasa**. Keduanya menggunakan **LoRa RA-02 SX1278 (433MHz)**.

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
1. `LoRa` oleh **Sandeep Mistry** (Wajib untuk Node & Gateway)
2. `LiquidCrystal I2C` oleh **Frank de Brabander** (Wajib untuk Gateway Node LCD)
3. `Adafruit MPU6050` oleh **Adafruit** (Node Sensor)
4. `Adafruit Unified Sensor` oleh **Adafruit** (Node Sensor)
5. `DHT sensor library` oleh **Adafruit** (Node Sensor)

---

## 2. Pengaturan Board Arduino IDE

### Gateway ESP32 WROOM-32

- **Board:** `ESP32 Dev Module` (bukan `ESP32S3 Dev Module`).
- **Upload Speed:** `115200` untuk uji awal.
- **Port:** COM board gateway, bukan otomatis COM node.
- **PSRAM:** Disabled untuk WROOM-32 tanpa PSRAM. Ukuran flash mengikuti modul sebenarnya; jangan menyalin pengaturan N16R8 node ke gateway.
- Serial Monitor: **115200**. Awal boot menampilkan `[BOARD] ESP32 WROOM-32` beserta pin yang aktif.

Firmware memilih pin WROOM-32 atau S3 berdasarkan target chip hasil pilihan board Arduino. Jenis chip selain dua itu ditolak saat compile. LCD dan JSON Serial sudah tersedia; pengiriman WiFi/Firebase belum diimplementasikan.

### Node ESP32-S3 N16R8

Sebelum melakukan klik **Upload / Flash**, pastikan menu **Tools** diatur seperti berikut:

* **Board**: `ESP32S3 Dev Module`
* **USB CDC On Boot**: `Enabled` untuk Serial lewat USB native; `Disabled` untuk Serial lewat USB-UART CH343.
* **Flash Size**: `16MB (128Mb)` *(Sesuai spesifikasi N16R8)*
* **Partition Scheme**: `16M Flash (3MB APP/9.9MB FATFS)` atau `Default 4MB with spiffs`
* **PSRAM**: `OPI PSRAM` *(Sesuai varian N16R8 yang memiliki 8MB Octal PSRAM)*
* **Upload Mode**: `UART0 / Hardware CDC`
* **Port**: Pilih port COM ESP32-S3 yang terdeteksi

---

## 3. Rangkuman Pinout Cepat (Wiring Cheat-Sheet)

### A. Node Sensor (Lereng Tebing & Hutan)
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

### B. Gateway Node (Penerima LoRa + LCD Display 16x2 I2C)
**Gateway yang dipakai: ESP32 WROOM-32.** Kabel harus mengikuti kolom WROOM-32. Jangan memakai GPIO6-11 WROOM-32 karena terkait memori flash.

| Sinyal | ESP32 WROOM-32 | ESP32-S3 alternatif |
| :--- | :--- | :--- |
| LoRa SCK | 18 | 12 |
| LoRa MISO | 19 | 13 |
| LoRa MOSI | 23 | 11 |
| LoRa NSS / CS | 5 | 10 |
| LoRa RST | 14 | 14 |
| LoRa DIO0 | 26 | 21 |
| LCD SDA | 21 | 8 |
| LCD SCL | 22 | 9 |

LoRa menggunakan **3.3V** dan GND bersama. LCD/backpack dengan pull-up SDA/SCL ke 5V perlu level shifter 3.3V/5V; GPIO ESP32 tidak menerima sinyal 5V.

Detail berikut berlaku untuk **gateway alternatif ESP32-S3**, bukan gateway WROOM-32:

| Komponen | Pin Modul | Sambungkan ke ESP32-S3 | Keterangan |
| :--- | :--- | :--- | :--- |
| **LCD 16x2 / 20x4 I2C** | SDA | **GPIO 8** (atau GPIO 21 pada ESP32 Classic) | I2C Data Bus |
| *(Backpack PCF8574)* | SCL | **GPIO 9** (atau GPIO 22 pada ESP32 Classic) | I2C Clock Bus |
| | VCC | **5V** (atau 3.3V jika backpack support) | Power Lampu & IC |
| | GND | **GND** | Ground bersama |
| **LoRa RA-02 (SX1278)** | SCK / MISO / MOSI | **GPIO 12 / GPIO 13 / GPIO 11** | Bus SPI FSPI ESP32-S3 |
| | CS (NSS) | **GPIO 10** | Chip Select LoRa |
| | RST | **GPIO 14** | Reset LoRa |
| | DIO0 | **GPIO 21** (atau GPIO 2 pada ESP32 Classic) | Digital Interrupt |
| | VCC | **3.3V (Wajib!)** | **JANGAN hubungkan ke 5V!** |
| | GND | **GND** | Ground bersama |
