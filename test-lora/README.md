# Panduan Pengujian LoRa Antara Node dan Gateway (TITEN)

Folder ini berisi kode pengujian khusus untuk memastikan modul **LoRa RA-02 (SX1278 433 MHz)** pada **Node** dan **Gateway** dapat saling berkomunikasi dengan baik tanpa gangguan sensor lainnya.

---

## 📁 Struktur File

```
test-lora/
├── test_node_sender/
│   └── test_node_sender.ino       <-- Upload ke ESP32 Node (Transmitter)
├── test_gateway_receiver/
│   └── test_gateway_receiver.ino   <-- Upload ke ESP32 Gateway (Receiver)
└── README.md                       <-- Panduan pengujian ini
```

---

## 🛠️ 1. Persiapan Hardware & Wiring

Sebelum menghubungkan kabel USB ke komputer, periksa hal-hal berikut:

1. **Antena Wajib Terpasang**:  
   Jangan pernah menyalakan board saat modul LoRa belum dipasangi antena (pegas atau omni 433 MHz), karena daya pancar RF yang terpantul balik dapat merusak chip SX1278.
2. **VCC Wajib 3.3V**:  
   Hubungkan VCC LoRa ke pin **3.3V** ESP32, **JANGAN ke 5V / VIN**!

### Ringkasan Sambungan Pin:

| Pin LoRa RA-02 | ESP32-S3 DevKitC-1 | ESP32 Klasik (WROOM-32) |
| :--- | :--- | :--- |
| **VCC** | **3.3V** | **3.3V** |
| **GND** | **GND** | **GND** |
| **SCK** | **GPIO 12** | **GPIO 18** |
| **MISO** | **GPIO 13** | **GPIO 19** |
| **MOSI** | **GPIO 11** | **GPIO 23** |
| **NSS / CS** | **GPIO 10** | **GPIO 5** |
| **RST** | **GPIO 14** | **GPIO 14** |
| **DIO0** | **GPIO 21** | **GPIO 2** |

> **Catatan Pemilihan Board:**  
> Secara default, kode telah diatur untuk **ESP32-S3**.  
> Jika salah satu board Anda adalah **ESP32 WROOM-32 Klasik**, cukup ubah baris di awal file sketch:
> ```cpp
> // #define BOARD_ESP32_S3
> #define BOARD_ESP32_CLASSIC
> ```

---

## 💻 2. Langkah Pengujian di Arduino IDE

### A. Install Library
Buka Arduino IDE -> **Tools** > **Manage Libraries...** -> cari `LoRa` oleh **Sandeep Mistry** -> klik **Install**.

### B. Flash Board 1 (Gateway Receiver)
1. Buka file `test-lora/test_gateway_receiver/test_gateway_receiver.ino`.
2. Hubungkan ESP32 Gateway ke laptop via USB.
3. Pilih board dan port COM yang sesuai:
   - Jika ESP32-S3: Board `ESP32S3 Dev Module`, pastikan **USB CDC On Boot: Enabled**.
   - Jika ESP32 Klasik: Board `ESP32 Dev Module`.
4. Klik tombol **Upload**.
5. Setelah selesai, buka **Serial Monitor** pada baudrate **115200**.
6. Anda akan melihat log:
   ```
   [OK] Gateway standby mendengarkan paket masuk dari Node...
   ```

### C. Flash Board 2 (Node Sender)
1. Buka file `test-lora/test_node_sender/test_node_sender.ino`.
2. Hubungkan ESP32 Node ke laptop (bisa menggunakan port USB kedua atau laptop lain).
3. Pilih board dan port COM Node yang sesuai.
4. Klik tombol **Upload**.
5. Buka **Serial Monitor** pada baudrate **115200**.
6. Node akan mulai mengirim pesan:
   ```
   [TX] Mengirim Paket #1: 'TITEN PING #1' ... TERKIRIM!
   ```

---

## 📊 3. Cara Membaca Hasil Pengujian

Pada Serial Monitor **Gateway**, paket yang masuk akan langsung muncul seperti berikut:

```text
[RX #1] Pesan: 'TITEN PING #1' | Ukuran: 14 Bytes | RSSI: -65 dBm | SNR: 9.25 dB
       --> Kualitas Sinyal: SANGAT KUAT (Excellent)
[RX #2] Pesan: 'TITEN PING #2' | Ukuran: 14 Bytes | RSSI: -67 dBm | SNR: 8.75 dB
       --> Kualitas Sinyal: SANGAT KUAT (Excellent)
```

### Indikator Sinyal:
* **RSSI (Received Signal Strength Indication)**:
  - `-30 s.d. -80 dBm`: Sinyal sangat kuat (jarak dekat / meja uji).
  - `-81 s.d. -105 dBm`: Sinyal bagus (jarak menengah / terhalang dinding).
  - `-106 s.d. -125 dBm`: Batas jangkauan maksimal (di lereng bukit).
* **SNR (Signal-to-Noise Ratio)**:
  - Positif (`> 0 dB`): Sinyal jauh lebih kuat daripada derau interferensi lingkungan.
  - Negatif (`-1 s.d. -15 dB`): Sinyal di bawah derau lingkungan, namun LoRa masih mampu mendemodulasi data.
