# RANCANGAN PINOUT & SKEMA PENGKABELAN TITEN
**Sistem Peringatan Dini Tanah Longsor & Kebakaran Hutan (MAGE 12 - ITS)**
**Tim Pengembang**: TRILOGY - SMK Budi Luhur, Kota Tangerang (2026)

---

## 1. Spesifikasi Hardware Acuan

| Kategori | Spesifikasi Komponen | Catatan Operasional |
| :--- | :--- | :--- |
| **Mikrokontroler Utama** | **ESP32-S3 DevKitC-1 N16R8** | 16MB Quad SPI Flash, 8MB Octal PSRAM, USB Type-C |
| **Mikrokontroler Gateway** | **ESP32 WROOM-32 biasa** | Pilih ESP32 Dev Module; pin berbeda dari node S3 |
| **Komunikasi Radio** | **LoRa RA-02 SX1278 (433 MHz)** | Antena 433 MHz, SPI Interface, Jangkauan 2–10 km |
| **Display Lokal Gateway** | **LCD 16x2 / 20x4 + Backpack I2C (PCF8574)** | Monitor status telemetri, RSSI, dan alarm bahaya di posko |
| **Sensor Longsor** | **MPU-6050 (GY-521)** | Kemiringan lereng (Tilt Pitch/Roll) & Getaran (Vibration) |
| | **Capacitive Soil Moisture V2.0** | Kejenuhan air tanah tanpa korosi (Analog 0–3.0V) |
| **Sensor Karhutla** | **DHT22 (AM2302)** | Suhu udara ekstrem & kelembapan udara kering |
| | **KY-026 Flame Sensor** | Deteksi radiasi optik api inframerah (Active LOW) |
| **Power & Battery** | **Voltage Divider Module 0–25V** | Monitoring sisa kapasitas baterai Li-ion 18650 |
| | **Panel Surya 5V/6V + TP4056 + 2x 18650** | Arsitektur mandiri *SoPoWake* (Solar Powered Wake-on-Threshold) |
| **Aktuator Lokal** | **Relay 1-Ch 3.3V + Buzzer 3V + LED COB 3V** | Peringatan instan lokal < 500ms tanpa ketergantungan internet |

---

## 2. Tabel Pinout ESP32-S3 DevKitC-1 (Hardware Riil)

> [!WARNING]
> **Peringatan Pin Terlarang ESP32-S3 N16R8:**
> Pin **GPIO 26 s.d. GPIO 32** terhubung langsung ke chip internal Octal PSRAM & Flash 16MB. Jangan pernah menyambungkan sensor/kabel ke pin-pin tersebut karena akan menyebabkan ESP32 mengalami *boot loop* / crash permanen.

### A. Tabel Pinout Node Sensor (Edge Device di Lereng/Hutan)

| Modul / Sensor | Pin Modul | Terhubung ke ESP32-S3 | Mode / Fungsi | Keterangan Teknis |
| :--- | :--- | :--- | :--- | :--- |
| **MPU-6050 (GY-521)** | VCC | **3.3V** | Power | Tegangan stabil 3.3V |
| | GND | **GND** | Ground | Ground bersama |
| | SDA | **GPIO 8** | I2C Data | Default hardware I2C ESP32-S3 |
| | SCL | **GPIO 9** | I2C Clock | Default hardware I2C ESP32-S3 |
| | INT | **GPIO 4** | RTC Wakeup / Interrupt | Ext0 interrupt: membangunkan ESP32 saat tebing bergeser mendadak |
| **Capacitive Soil V2**| VCC | **3.3V** | Power | Wajib 3.3V agar sinyal tidak merusak ADC |
| | GND | **GND** | Ground | Ground bersama |
| | AOUT | **GPIO 1** | ADC1_CH0 (Analog) | Nilai 1300 (basah jenuh) s.d. 3100 (kering) |
| **DHT22 (AM2302)** | VCC | **3.3V** | Power | Disertai kapasitor decoupling internal |
| | GND | **GND** | Ground | Ground bersama |
| | DATA | **GPIO 2** | Digital I/O (Pull-up 10k) | Sinyal satu kabel (*single-bus*) |
| **KY-026 Flame Sensor**| VCC | **3.3V** | Power | Sensor api inframerah |
| | GND | **GND** | Ground | Ground bersama |
| | DO | **GPIO 3** | Digital Input | `LOW` saat api terdeteksi di sekitar |
| **Battery Divider 0-25V**| VCC (+) | **Baterai 18650 (+)** | Input Divider | Mengukur tegangan 3.0V – 4.2V baterai |
| | GND (-) | **GND** | Ground | Ground bersama |
| | S (Signal) | **GPIO 5** | ADC1_CH4 (Analog) | Rasio 5:1 menghasilkan 0.6V–0.84V ke ADC |
| **Relay 1-Ch 3.3V** | VCC | **3.3V** atau **5V** | Power Relay | Menyuplai koil relay |
| | GND | **GND** | Ground | Ground bersama |
| | IN | **GPIO 6** | Digital Output | `HIGH` mengaktifkan Sirine & LED Strobe |
| **LoRa RA-02 (SX1278)** | VCC | **3.3V (Wajib 3.3V!)** | Power Radio | **JANGAN 5V!** SX1278 rusak jika diberi 5V |
| | GND | **GND** | Ground | Ground bersama |
| | SCK | **GPIO 12** | SPI SCK | Hardware FSPI Bus |
| | MISO | **GPIO 13** | SPI MISO | Hardware FSPI Bus |
| | MOSI | **GPIO 11** | SPI MOSI | Hardware FSPI Bus |
| | NSS / CS | **GPIO 10** | SPI Chip Select | Kontrol komunikasi paket |
| | RST | **GPIO 14** | Digital Output | Reset radio transceiver |
| | DIO0 | **GPIO 21** | Digital Interrupt | Notifikasi pengiriman / penerimaan paket selesai |

---

### B. Tabel Pinout Gateway Node (Posko / Receiver + LCD Display)

**Gateway fisik yang dikonfirmasi memakai ESP32 WROOM-32.** Firmware memilih pin berdasarkan target chip di Arduino IDE. Untuk gateway ini pilih `ESP32 Dev Module` dan gunakan tabel berikut:

| Sinyal | GPIO ESP32 WROOM-32 |
| :--- | :--- |
| LoRa SCK | 18 |
| LoRa MISO | 19 |
| LoRa MOSI | 23 |
| LoRa NSS / CS | 5 |
| LoRa RST | 14 |
| LoRa DIO0 | 26 |
| LCD SDA | 21 |
| LCD SCL | 22 |

LoRa VCC ke **3.3V**, GND bersama. Jangan memakai GPIO6-11 WROOM-32 yang terkait memori flash. Untuk LCD/backpack dengan pull-up I2C ke 5V, gunakan level shifter bidirectional 3.3V/5V; jangan membawa sinyal 5V langsung ke GPIO.

**Tabel di bawah khusus alternatif ESP32-S3**, bukan gateway WROOM-32 yang dipakai sekarang:

| Modul / Komponen | Pin Modul | Terhubung ke ESP32-S3 | Mode / Fungsi | Keterangan Teknis |
| :--- | :--- | :--- | :--- | :--- |
| **LCD 16x2 / 20x4 I2C** | VCC | **5V (VIN / VBUS)** | Power LCD | Driver PCF8574 dan backlight membutuhkan 5V stabil |
| *(Backpack PCF8574)* | GND | **GND** | Ground | Ground bersama |
| | SDA | **GPIO 8** | I2C Data | Jalur data komunikasi LCD (Alamat: `0x27` / `0x3F`) |
| | SCL | **GPIO 9** | I2C Clock | Jalur clock komunikasi LCD |
| **LoRa RA-02 (SX1278)** | VCC | **3.3V (Wajib!)** | Power Radio | **Wajib 3.3V! Dilarang 5V!** |
| | GND | **GND** | Ground | Ground bersama |
| | SCK | **GPIO 12** | SPI SCK | Hardware FSPI Bus |
| | MISO | **GPIO 13** | SPI MISO | Hardware FSPI Bus |
| | MOSI | **GPIO 11** | SPI MOSI | Hardware FSPI Bus |
| | NSS / CS | **GPIO 10** | SPI Chip Select | Kontrol penerimaan paket |
| | RST | **GPIO 14** | Digital Output | Reset modul LoRa |
| | DIO0 | **GPIO 21** | Digital Interrupt | Interupsi penerimaan paket RF masuk |

---

## 3. Diagram Skema Pengkabelan (Wiring Schematic)

### A. Skema Node Sensor (Lereng Tebing)

```
                            +--------------------------+
                            |   PANEL SURYA MINI 5V    |
                            +------------+-------------+
                                         |
                                         v
                            +--------------------------+
                            |   TP4056 CHARGER TYPE-C  |
                            | IN+ / IN- : Dari Solar   |
                            | B+  / B-  : Ke 2x 18650  |
                            | OUT+/ OUT-: Ke Board VCC |
                            +------------+-------------+
                                         |
                                         v
                           +----------------------------+
                           |  2x BATERAI 18650 PARALEL  |
                           |  Tegangan: 3.7V - 4.2V     |
                           +-------------+--------------+
                                         |
               +-------------------------+-------------------------+
               |                                                   |
               v                                                   v
   +-----------------------+                           +-----------------------+
   | BATTERY VOLTAGE SENSOR|                           | RELAY 1-CHANNEL 3.3V  |
   | S    -> GPIO 5        |                           | IN   -> GPIO 6        |
   | VCC  -> Baterai (+)   |                           | NO   -> Buzzer & LED  |
   | GND  -> GND           |                           | COM  -> Power 3V-5V   |
   +-----------------------+                           +-----------+-----------+
                                                                   |
                                                                   v
                                                        +---------------------+
                                                        | BUZZER 120dB & LED  |
                                                        +---------------------+

   +-----------------------+                           +-----------------------+
   |   MPU-6050 (GY-521)   |                           |  LORA RA-02 (SX1278)  |
   | SDA  -> GPIO 8        |                           | SCK  -> GPIO 12       |
   | SCL  -> GPIO 9        |                           | MISO -> GPIO 13       |
   | INT  -> GPIO 4 (Wake) |                           | MOSI -> GPIO 11       |
   | VCC  -> 3.3V          |                           | NSS  -> GPIO 10       |
   | GND  -> GND           |                           | RST  -> GPIO 14       |
   +-----------------------+                           | DIO0 -> GPIO 21       |
                                                       | VCC  -> 3.3V (Wajib!) |
   +-----------------------+                           | GND  -> GND           |
   | CAPACITIVE SOIL V2.0  |                           +-----------------------+
   | AOUT -> GPIO 1 (ADC)  |
   | VCC  -> 3.3V          |                           +-----------------------+
   | GND  -> GND           |                           |   KY-026 FLAME SENSOR |
   +-----------------------+                           | DO   -> GPIO 3        |
                                                       | VCC  -> 3.3V          |
   +-----------------------+                           | GND  -> GND           |
   |     DHT22 (AM2302)    |                           +-----------------------+
   | DATA -> GPIO 2        |
   | VCC  -> 3.3V          |
   | GND  -> GND           |
   +-----------------------+
```

### B. Skema Gateway Node + LCD Display 16x2 I2C (Posko Warga)

```
       +-----------------------------------------------------------+
       |             ADAPTOR 5V / USB TYPE-C POWER                 |
       +-----------------------------+-----------------------------+
                                     |
                                     v
                       +---------------------------+
                       | ESP32-S3 DEVKITC-1 N16R8  |
                       | (Gateway Concentrator)    |
                       +-------------+-------------+
                                     |
             +-----------------------+-----------------------+
             |                                               |
             v                                               v
+-------------------------+                     +-------------------------+
|   LCD 16x2 / 20x4 I2C   |                     |   LORA RA-02 (SX1278)   |
|   (PCF8574 Backpack)    |                     |   (Transceiver 433MHz)  |
+-------------------------+                     +-------------------------+
| VCC  -> 5V (VIN/VBUS)   |                     | VCC  -> 3.3V (Wajib!)   |
| GND  -> GND             |                     | GND  -> GND             |
| SDA  -> GPIO 8          |                     | SCK  -> GPIO 12         |
| SCL  -> GPIO 9          |                     | MISO -> GPIO 13         |
+-------------------------+                     | MOSI -> GPIO 11         |
                                                | NSS  -> GPIO 10         |
                                                | RST  -> GPIO 14         |
                                                | DIO0 -> GPIO 21         |
                                                +-------------------------+
```

---

## 4. Perbandingan Pinout jika Menggunakan ESP32 Klasik (WROOM-32)

Jika prototipe menggunakan board ESP32 30-pin klasik (ESP-WROOM-32), gunakan tabel konversi berikut:

| Komponen & Fungsi Sinyal | ESP32-S3 (Acuan Utama) | ESP32 Klasik (WROOM-32) | Catatan & Alasan Arsitektur |
| :--- | :--- | :--- | :--- |
| **I2C SDA / SCL (Node & LCD)** | **GPIO 8 / GPIO 9** | **GPIO 21 / GPIO 22** | Default hardware pin I2C berbeda antar arsitektur SoC |
| **Soil Probe (ADC)** | **GPIO 1** | **GPIO 34** | GPIO 34 input-only ADC1 pada ESP32 Classic |
| **Battery Divider** | **GPIO 5** | **GPIO 36 (VP)** | GPIO 36 input-only ADC1 pada ESP32 Classic |
| **MPU Wake Interrupt** | **GPIO 4** | **GPIO 33** | Keduanya RTC GPIO untuk ext0 wakeup |
| **DHT22 Data** | **GPIO 2** | **GPIO 27** | GPIO digital dengan software pull-up |
| **KY-026 Flame Sensor DO** | **GPIO 3** | **GPIO 25** | Input digital aktif rendah (*Active LOW*) |
| **Relay Sirine & LED** | **GPIO 6** | **GPIO 26** | Output digital pemicu saklar relay |
| **LoRa SCK / MISO / MOSI**| **GPIO 12 / 13 / 11** | **GPIO 18 / 19 / 23** | Pin FSPI ESP32-S3 vs VSPI ESP32 Classic |
| **LoRa CS / RST** | **GPIO 10 / 14** | **GPIO 5 / 14** | Pin Chip Select dan Reset LoRa |
| **LoRa DIO0** | **GPIO 21** | **GPIO 2** (atau GPIO 4) | *Catatan: Pada ESP32 Classic, GPIO 21 dipakai I2C LCD, sehingga DIO0 dipindah ke GPIO 2!* |

---

## 5. Checklist Validasi Lapangan Sebelum Nyala Pertama (Safety Rules)

1. [ ] **Verifikasi Jalur Tegangan 3.3V vs 5V**:
   - Modul LoRa RA-02 **hanya boleh menerima 3.3V**. Sambungan 5V akan membakar chip Semtech SX1278 seketika.
   - Modul LCD I2C disarankan mendapat daya dari **5V (VIN / VBUS)** agar lampu latar (*backlight*) terang maksimal dan kontras teks jelas terbaca.
2. [ ] **Antena LoRa Terpasang**: Jangan pernah memprogram atau menyalakan transmisi LoRa tanpa antena terpasang pada port SMA/IPEX, karena energi radio pantulan (*reflected RF energy*) dapat merusak power amplifier transmisi.
3. [ ] **Common Ground**: Pastikan semua ground (`GND`) dari LCD, modul LoRa, sensor, relay, baterai, dan ESP32 terhubung satu sama lain (*Common Ground*).
4. [ ] **Penyesuaian Trimmer Kontras LCD**: Jika setelah dihidupkan layar LCD biru menyala tetapi teks tidak muncul, putar potensiometer biru kecil di belakang modul I2C backpack menggunakan obeng minus kecil hingga tulisan terlihat jelas.
5. [ ] **Kalibrasi Sensor Tanah**: Sebelum ditanam ke tanah tebing, ukur nilai analog di udara kering (0%) dan di wadah air basah (100%) menggunakan Serial Monitor, lalu sesuaikan konstanta `SOIL_ADC_DRY_AIR` dan `SOIL_ADC_WET_WATER` pada file firmware.
