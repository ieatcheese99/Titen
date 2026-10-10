# TITEN: uji sensor, USB web, lalu gateway

Tahap ini memakai USB laptop. Baterai, relay, buzzer, dan LED belum perlu dipasang. Upload berhasil setelah expansion board dilepas, tetapi ini belum membuktikan titik kesalahan expansion board. Rakit dan uji dahulu tanpa expansion board.

## 1. Upload firmware untuk pengujian

Buka `firmware/node_bench/node_bench.ino` di Arduino IDE. Sketch ini membaca berulang setiap 2,5 detik, tidak masuk deep sleep, tidak memancarkan LoRa, dan tidak mengendalikan alarm. Sketch produksi `node_sensor.ino` membaca sekali lalu tidur 6 jam; jangan memakai siklus itu untuk tes sensor yang terus berubah.

Gunakan ESP32S3 Dev Module. Untuk board N16R8: Flash Size 16MB dan OPI PSRAM. Gunakan Upload Mode UART0 / Hardware CDC, Upload Speed 115200, serta port yang berhasil dipakai upload. Jika melalui USB native, gunakan Hardware CDC and JTAG serta USB CDC On Boot Enabled; jika USB-UART CH343 untuk Serial Monitor, gunakan USB CDC On Boot Disabled agar `Serial` keluar melalui UART0.

Setelah upload, buka Serial Monitor 115200 dan tekan RST sekali. Baris JSON `"type":"titen_bench"` harus muncul berulang. Dengan board kosong, MPU/DHT akan gagal membaca; ini normal dan nilainya tetap `null`.

## 2. Pasang sensor satu per satu

Cabut USB sebelum mengubah wiring. Semua sensor pada tabel menggunakan 3.3V dan GND bersama; jangan memberi sinyal 5V ke GPIO ESP32-S3. Hubungkan kembali dan amati sensor yang baru dipasang.

| Sensor | Sambungan | Tanda berhasil |
| --- | --- | --- |
| MPU6050 | SDA GPIO8; SCL GPIO9; VCC 3.3V; GND | `mpu_status=ok`; kemiringan berubah saat sumbu pitch dimiringkan. INT GPIO4 belum diperlukan untuk uji USB. |
| DHT22 | DATA GPIO2; VCC 3.3V; GND | `dht_status=ok`; suhu/kelembapan berupa angka. Modul 3 pin biasanya sudah memiliki pull-up; sensor telanjang perlu pull-up sesuai datasheet. |
| Soil kapasitif | AOUT GPIO1; VCC 3.3V; GND | Aktifkan soil di halaman uji. ADC berubah saat probe dipindahkan dari kondisi kering ke tanah lembap. Persentase belum dikalibrasi. Jangan merendam bagian elektronik. |
| Flame | DO GPIO3; VCC 3.3V; GND | Aktifkan flame di halaman uji. Sketch menganggap DO aktif LOW; cocokkan respons modul sebenarnya. Sensor flame belum membuktikan deteksi kebakaran hutan. |

Soil/flame default nonaktif karena input kosong bisa menghasilkan nilai acak. Centang setelah wiring sudah dikonfirmasi. MPU memeriksa alamat 0x68 dan 0x69. Orientasi pitch memengaruhi nilai tilt: mengubah sumbu lain tidak selalu mengubah pitch. Pembacaan bukan klasifikasi AMAN/AWAS.

## 3. Lihat data di web lokal

1. Tutup Serial Monitor/Plotter Arduino supaya port tidak terkunci.
2. Jika Laragon Apache berjalan, buka `http://localhost/Titen/uji-node.html` di Chrome/Edge desktop.
3. Alternatif jika Laragon belum berjalan: buka terminal di folder proyek dan jalankan:

   ```powershell
   python -m http.server 8765 --bind 127.0.0.1
   ```

   Lalu buka `http://localhost:8765/uji-node.html`. Biarkan terminal server berjalan selama pengujian; Ctrl+C untuk menghentikan.
4. Klik **Hubungkan ESP32**, pilih port yang sama dengan upload. Jika belum ada sampel, tekan RST sekali. Tunggu sekitar 3–5 detik.
5. Aktifkan soil/flame hanya jika terpasang. Data sensor tampil nyata; pembacaan gagal ditampilkan sebagai `—`. Tombol **Unduh sampel JSON** menyimpan maksimal 500 sampel terbaru pada sesi browser ini.
6. Uji minimal 10 sampel berurutan. Cabut USB: halaman harus berhenti menerima data, tidak membuat data pengganti. Hubungkan kembali melalui tombol dan aktifkan ulang sensor yang terpasang.
7. Klik **Putuskan koneksi** sebelum upload ulang atau membuka Serial Monitor. Satu port hanya dipakai satu aplikasi pada satu waktu.

Halaman USB adalah alat diagnosis node. `received_at` adalah waktu browser menerima sampel, `uptime_ms` adalah waktu sejak board menyala. Tidak ada timestamp pengukuran UTC yang diklaim dari uptime. Halaman ini belum menguji LoRa, gateway, cloud, baterai, atau alarm fisik.

## 4. Sesudah sensor lulus: uji radio dan gateway

Alur target lengkap: **sensor → node → LoRa → gateway → WiFi/backend → web/aplikasi**.

- Siapkan dua board dan dua modul LoRa. Pasang antena yang sesuai sebelum memancarkan. Node memakai S3; gateway yang dikonfirmasi memakai WROOM-32. Pilih `ESP32 Dev Module` untuk gateway; firmware memilih pin SCK18/MISO19/MOSI23/NSS5/RST14/DIO0=26 dan LCD SDA21/SCL22. Kabel harus mengikuti pin tersebut, bukan pin S3.
- Cocokkan node/gateway: 433MHz, SF10, bandwidth 125kHz, coding rate dan sync word yang sama. Mulai jarak dekat.
- Gateway dinyalakan dahulu, lalu node mengirim. Lulus jika gateway menerima node ID dan ukuran paket benar, CRC valid, serta nilai sama dengan Serial node. Tulisan node “paket dipancarkan” saja belum membuktikan gateway menerima.
- Firmware produksi perlu mode sampling berulang untuk demo, guard sensor gagal, dan penanganan LoRa gagal; data DHT fallback 27.5°C/65% tidak boleh dipakai sebagai bukti sensor.
- Gateway hanya mencetak JSON ke Serial dan menampilkan LCD. Pengiriman WiFi/backend masih perlu diimplementasikan dan diuji setelah penerimaan LoRa berhasil.
- Web HTML utama (`index.html`/`app.js`) masih simulasi. Untuk melihat sensor di sana, implementasikan koneksi data nyata. Aplikasi Flutter mempunyai pembaca Firebase, tetapi gateway/backend harus menulis kontrak yang sesuai, disertai autentikasi dan aturan database yang sudah diuji.

### Buka web untuk kode node/gateway biasa

1. Upload `node_sensor.ino` ke node S3 dan `gateway_node.ino` ke gateway WROOM-32 dengan wiring gateway yang sudah diperbarui. Jangan memakai `node_bench` untuk tes radio karena sketch tersebut tidak mengirim LoRa.
2. Pasang antena dan suplai 3.3V masing-masing modul LoRa. Untuk uji awal dekatkan kedua perangkat sekitar 1–3 meter, lalu nyalakan gateway dahulu.
3. Hubungkan gateway ke USB laptop; tutup Serial Monitor/Plotter. Jalankan server lokal seperti langkah sebelumnya.
4. Buka `http://localhost:8765/uji-gateway.html` di Chrome/Edge desktop, atau `http://localhost/Titen/uji-gateway.html` jika Apache Laragon sudah berjalan.
5. Klik **Hubungkan gateway**, pilih COM gateway (terdeteksi COM5/CP210x saat pemeriksaan; dapat berubah). Tekan RST gateway sekali, tunggu log `[OK] Gateway siap mendengarkan...`.
6. Tekan RST **node**. Node membaca lalu mengirim sekali sebelum tidur 6 jam; halaman menerima JSON gateway dan menampilkan RSSI/SNR serta data yang dilaporkan node. Jika gateway mencetak CRC rusak, paket tersebut tidak ditampilkan sebagai sampel.
7. Ulangi setelah mengubah kondisi sensor. Unduh JSON untuk bukti pengujian. Hitungan paket adalah jumlah yang diterima browser selama sesi, bukan seluruh paket sepanjang hidup gateway.

Tes USB ini belum memerlukan internet 4G. Internet baru diperlukan untuk tahap gateway WiFi → backend/Firebase → web jarak jauh. Menyambungkan gateway ke hotspot saja belum mengaktifkan alur itu; firmware saat ini belum mempunyai koneksi WiFi/pengiriman cloud. Validitas sensor dari payload lama tidak dapat dipastikan: DHT fallback dan input belum terpasang tetap harus diperiksa pada node. Halaman gateway melabeli data sebagai laporan node, bukan bukti AMAN atau bukti alarm berbunyi.

## 5. Kriteria selesai untuk tahap ini

- Upload node berhasil tanpa expansion board.
- JSON diterima berulang selama minimal 10 sampel; tidak tidur 6 jam.
- Sensor yang terpasang merespons perubahan nyata, sensor gagal tidak diganti angka contoh.
- Browser menampilkan sampel USB yang sama dan waktu penerimaan; berhenti memperbarui ketika USB terputus.
- Soil masih ADC mentah sampai kalibrasi dilakukan; baterai/buzzer/LED/LoRa/cloud tetap berstatus belum diuji.

Referensi: [Web Serial Chrome](https://developer.chrome.com/docs/capabilities/serial), [USB ESP32-S3](https://docs.espressif.com/projects/arduino-esp32/en/latest/tutorials/cdc_dfu_flash.html), [MPU6050 Adafruit](https://github.com/adafruit/Adafruit_MPU6050), [DHT Adafruit](https://github.com/adafruit/DHT-sensor-library).
