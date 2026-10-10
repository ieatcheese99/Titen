# Audit pinout dan rencana penyelesaian demo TITEN

Tanggal audit: **7 Oktober 2026 (Asia/Jakarta)**.

Target yang dikonfirmasi pengguna: **demo lomba dengan seluruh sistem berfungsi**. Lingkup minimum: satu node sensor fisik, satu gateway fisik, alarm lokal, LoRa, internet, Firebase, aplikasi Android, riwayat, notifikasi, dan kendali sirine yang memiliki konfirmasi perangkat.

**Kesimpulan: pemilihan GPIO utama PINOUT_V2 masuk akal, tetapi dokumen belum boleh dipakai sebagai skema final tanpa koreksi daya dan penyelarasan firmware. Sistem belum tersambung dari sensor sampai aplikasi.**

Audit ini membaca kode, dokumen, foto komponen, BOM proposal, dan dokumentasi produsen. Audit ini belum mengukur rangkaian, mengunggah firmware, menguji radio, atau memeriksa konfigurasi Firebase yang sudah terpasang di cloud. Firmware dan aplikasi tidak diubah oleh audit ini.

## 1. Apa yang sudah dapat diverifikasi

- Foto komponen memperlihatkan board berlabel ESP32-S3-N16R8 dengan extension board, MPU-6050/GY-521, DHT22 modul tiga pin, flame HW-072, soil HW-390, voltage divider, relay JQC3F-03VDC-C, COB bertanda 3V, dan buzzer. Foto radio belum cukup tajam untuk mengesahkan seluruh label; RA-02 SX1278 menjadi basis dokumen dan firmware, perlu dicek pada unit asli.
- Pilihan GPIO node di bawah tidak saling bertabrakan dan menghindari pin memori N16R8. GPIO4 merupakan RTC GPIO untuk wake. GPIO1 dan GPIO5 adalah ADC1. [Dokumentasi GPIO Espressif](https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/gpio.html).
- Firmware node dan gateway memakai struktur packed 16 byte dan CRC16 atas 14 byte pertama yang sama. Parameter eksplisit keduanya sama: 433 MHz, SF10, BW 125 kHz. CR, sync word, dan CRC radio perlu ditetapkan eksplisit bersama pada versi final, bukan hanya mengandalkan default library.
- BOM proposal mencantumkan satu ESP32-S3 dan dua modul LoRa. MCU gateway tambahan belum tercantum; ini tidak membuktikan apakah tim sudah membelinya setelah proposal dibuat.
- Belum ada bukti pengujian fisik terversi yang ditemukan. Checklist dan angka target pada roadmap adalah rencana, bukan hasil ukur.

## 2. Pinout GPIO acuan untuk demo

Angka adalah **nomor GPIO**, bukan nomor urut kaki header. Pemetaan berikut mengesahkan pilihan fungsi pin; persyaratan tegangan, beban, dan level shifting tetap berlaku.

### Node: ESP32-S3 N16R8

| Sinyal | GPIO | Hasil audit / tindakan |
| --- | --- | --- |
| MPU SDA / SCL | 8 / 9 | Sesuai firmware dan V2; jalur I2C harus berada pada level 3,3V |
| MPU INT | 4 | Tepat untuk RTC wake; konfigurasi interrupt MPU belum dibuat |
| Soil AOUT | 1 | ADC1_CH0; kalibrasi pada tegangan suplai dan tanah yang dipakai |
| DHT22 DATA | 2 | Sesuai; periksa pull-up modul ke 3,3V |
| Flame DO | **7** | V2 disarankan; firmware masih GPIO3 pada node_sensor.ino:31 |
| Voltage divider S | 5 | ADC1_CH4; ukur rasio resistor dan tegangan maksimal input ADC |
| Relay IN | 6 | Sesuai; buktikan polaritas dan keadaan OFF saat boot/reset/tidur |
| LoRa SCK / MISO / MOSI | 12 / 13 / 11 | Sesuai |
| LoRa NSS / RST / DIO0 | 10 / 14 / 21 | Sesuai |
| Sensor power enable | 15, opsional | Hanya kontrol saklar daya; bukan sumber VCC langsung |

Hindari GPIO35-37 pada N16R8 karena dipakai memori octal. GPIO26-32 juga terkait bus memori dan tidak tersedia pada header ini. GPIO0/3/45/46 adalah strapping; GPIO19/20 dipakai USB native; GPIO43/44 UART0; GPIO39-42 JTAG. Pin antarmuka tersebut **dicadangkan untuk proyek**, bukan semuanya pin yang secara elektrik dilarang. LED GPIO38 versus GPIO48 bergantung revisi board/clone. [Panduan board Espressif](https://documentation.espressif.com/esp-dev-kits/en/latest/esp32s3/esp32-s3-devkitc-1/user_guide_v1.0.html).

### Gateway: ESP32 WROOM-32 dikonfirmasi pengguna

| Sinyal | Jika ESP32 WROOM-32 | Jika ESP32-S3 |
| --- | --- | --- |
| LoRa SCK / MISO / MOSI | 18 / 19 / 23 | 12 / 13 / 11 |
| LoRa NSS / RST / DIO0 | 5 / 14 / 26 | 10 / 14 / 21 |
| LCD SDA / SCL | 21 / 22 | 8 / 9 |
| Buzzer posko opsional | 25 lewat driver | 6 lewat driver |
| Tombol mute opsional | 27 ke GND | 7 ke GND |

Pada audit awal firmware gateway hanya memakai pinmap S3. Setelah konfirmasi board WROOM-32, firmware kini memilih pin WROOM-32 atau S3 berdasarkan target chip hasil pilihan board Arduino. Untuk gateway fisik pilih **ESP32 Dev Module** dan ikuti kolom WROOM-32; GPIO6-11 klasik terkait flash. Pengujian penerimaan LoRa dan LCD pada perangkat tetap diperlukan.

Pada **kedua pilihan board**, LCD/backpack 5V dengan pull-up I2C ke 5V perlu level shifter bidirectional 3,3V/5V. PCF8574 sendiri mendukung 2,5-6V, tetapi modul LCD/backlight belum tentu bekerja baik pada 3,3V. Memindahkan pull-up ke 3,3V saja juga tidak menjamin HIGH valid saat PCF8574 disuplai 5V: VIH minimum 0,7 x VCC. [Datasheet TI PCF8574](https://www.ti.com/lit/ds/symlink/pcf8574.pdf).

## 3. Koreksi daya sebelum perakitan final

| Temuan pada PINOUT_V2.md | Koreksi yang diperlukan |
| --- | --- |
| Baris 159: buzzer nominal 3V langsung VBAT | VBAT penuh mencapai 4,2V. Periksa rentang tegangan buzzer; gunakan suplai sesuai rating jika 4,2V tidak diizinkan. Rating arus dan klaim 120dB belum terbukti. |
| Baris 160: resistor COB 4,7 ohm 1W dianggap pasti tepat | Nilainya harus dihitung dari Vf, arus nominal, jumlah COB, dan rentang baterai. Pakai driver arus konstan bila sesuai. Jangan mengesahkan nilai tetap hanya berdasarkan tulisan 3V. |
| Baris 204: seluruh sensor, LoRa dan koil relay mengambil rail 3V3 board | Hitung arus gabungan MCU + radio TX + koil + sensor dan kemampuan regulator board asli. Ukur drop tegangan saat TX dan alarm bersamaan; kapasitor saja tidak memperbaiki regulator yang kekurangan arus. |
| Baris 226-243: panel + dioda + TP4056 dianggap jalur surya final | TP4056 adalah charger satu sel, bukan otomatis pengatur panel dan pemisah daya beban. Validasi arus charge/RPROG, tegangan panel tanpa beban dan saat berbeban, suhu, terminasi, serta charge sambil alat hidup. Gunakan desain load-sharing/power-path yang sesuai. |
| Baris 243: dioda seri dianggap solusi tegangan panel 6V | Dioda Schottky bukan regulator/clamp. Tegangan drop berubah terhadap arus; satu dioda tidak menjamin input charger aman. Drop juga mengurangi headroom panel 5V. |
| Baris 248: LDO 3,3V langsung baterai 3,0-4,2V | LDO tidak dapat menaikkan 3,0V menjadi 3,3V. Pilih buck-boost yang sesuai atau tetapkan batas cutoff/dropout dan rentang operasi yang sudah diuji. |
| Baris 102/255: soil VCC dapat melalui GPIO15 | VCC harus dari rail yang disaklar MOSFET/load switch. Jika memakai P-MOS di rail 3,3V: source ke 3V3, drain ke 3V3_SW, gate dengan pull-up ke source; LOW menghidupkan. Cegah back-power lewat pin sinyal dan beri waktu warm-up sensor. |
| Baris 135-139: divider 5:1 dan header + NC | Foto belum membuktikan seluruh jalur. Cek kontinuitas, ukur nilai resistor/rasio, dan konfirmasi header sebelum dihubungkan. |

Untuk LoRa gunakan suplai **3,3V** dan antena yang cocok. [Ai-Thinker Ra-02](https://docs.ai-thinker.com/en/Ra-02/index.html). Daya TX, jangkauan, serta pemakaian radio di lokasi demo harus ditetapkan sesuai hasil uji dan ketentuan setempat; 2-10 km bukan jaminan.

Pada modul TP4056 dengan proteksi low-side DW01 + MOSFET yang benar-benar terpasang, GND sistem di OUT-, bukan B-, supaya proteksi tidak dilewati. Periksa tipe modul dan holder: **1S2P paralel**, bukan holder dua sel seri. Pilih sel sehat yang cocok dan sudah diseimbangkan tegangannya sebelum dirakit. Fuse, kabel, konektor dan batas arus harus sesuai beban, bukan otomatis 2A untuk semua konfigurasi.

Rujukan koreksi charger: [TP4056 produsen](https://toppwr.com/eproduct/view.php?id=478), [Microchip AN1149 tentang load sharing](https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ApplicationNotes/ApplicationNotes/01149c.pdf), dan [MCP73871 power-path](https://onlinedocs.microchip.com/oxy/GUID-C6E38B72-C221-4B07-9F6D-CFD13054F19A-en-US-1/GUID-6741FC5B-46C7-481D-B635-739D3C66330E.html). Rekomendasi regulator perlu memperhitungkan dropout; contoh [AP2112](https://www.diodes.com/datasheet/download/AP2112.pdf).

## 4. Yang perlu kamu siapkan dan rakit

Status "belum tercantum" berasal dari BOM proposal, bukan pemeriksaan stok terkini.

| Kebutuhan | Jumlah minimum | Status / keputusan |
| --- | --- | --- |
| MCU gateway | 1 | Belum tercantum; pilih WROOM-32 atau S3 dan kunci profil firmware |
| LoRa + antena + pigtail yang cocok | 2 set | Ada di BOM; pastikan kedua set benar-benar tersedia dan cocok band |
| LCD I2C + level shifter bidirectional | 1 set | Belum tercantum; diperlukan bila menampilkan LCD posko 5V |
| Adaptor gateway USB 5V dan kabel data | 1 set | Sesuaikan kapasitas arus seluruh beban gateway |
| Regulator node baterai ke rail board | 1 | Belum tercantum; MT3608 ke 5V adalah kandidat prototipe, wajib diuji stabilitas dan konsumsi |
| Charger, proteksi baterai, holder/pack 1S2P | 1 set | Sebagian di BOM; topologi dan kecocokan panel belum terverifikasi |
| Driver/suplai alarm sesuai buzzer dan COB | 1 set | Nilai komponen menunggu rating dan arus ukur |
| Kapasitor radio, resistor pull-up/pull-down, fuse/saklar | Sesuai skema final | Belum lengkap di BOM; pilih nilai setelah perhitungan |
| PCB lubang/PCB, terminal/JST, isolasi, dudukan | 1 set | Untuk rakitan final yang tidak mengandalkan jumper breadboard |
| Shield DHT berventilasi dan pelindung optik flame | 1 set | DHT membaca udara luar; sensor tidak terkena hujan atau matahari langsung |
| Multimeter, solder, catu uji, pengukur sudut | 1 set tim | Untuk bukti tegangan, arus, kalibrasi dan perakitan |
| HP Android + WiFi/hotspot demo | 1 set | Uji app foreground, background, dan layar terkunci |

MPU harus terpasang kaku dengan orientasi yang dicatat. Ukur dimensi box asli sebelum mengikuti blueprint. Bagian elektronik soil tidak ikut direndam; lapisan pelindung probe harus diuji ulang karena dapat mengubah kalibrasi.

## 5. Perbaikan software yang bisa dikerjakan

P0 = wajib agar demo tersambung dan tidak menampilkan keberhasilan palsu. P1 = wajib sebelum demo final dinyatakan selesai.

| Prio | Pekerjaan | Bukti saat audit | Hasil yang diharapkan |
| --- | --- | --- | --- |
| P0 | Selaraskan pinmap node/gateway dan kunci versi board core/library | node_sensor.ino:31; gateway_node.ino:20-34 | Profil S3/WROOM eksplisit, firmware compile untuk hardware pilihan |
| P0 | Hubungkan gateway ke WiFi, waktu, dan RTDB | gateway_node.ino:154-165 hanya Serial JSON/LCD | Satu paket sensor asli muncul di latest dan history dengan waktu yang benar |
| P0 | Pisahkan interval sampling dari heartbeat dan konfigurasi motion wake | node_sensor.ino:51,132-138,175,247-251 | Api/suhu tetap diperiksa saat node tidak bergerak; interrupt MPU teruji |
| P0 | Perbaiki kegagalan sensor dan kehilangan data | node_sensor.ino:169-170; dashboard_providers.dart:47,83-84 | Sensor putus/loading/error/offline tampil sebagai masalah, bukan AMAN |
| P0 | Ganti history mock dengan query history asli | firebase_node_repository.dart:127-128 | Grafik dan ekspor berasal dari paket fisik |
| P0 | Buat alur alert dan pengirim FCM di backend terpercaya | notification_service.dart baru menerima pesan dan subscribe topic | Notifikasi dari kejadian fisik diterima HP ketika background/layar terkunci |
| P0 | Implementasikan kendali sirine beserta balasan perangkat | firebase_node_repository.dart:137-145; emergency_providers.dart:25-26 | UI menunjukkan pending, executed, failed/expired berdasarkan ACK, termasuk OFF |
| P1 | Simpan baseline tilt dan kalibrasi di NVS | node_sensor.ino:162-164 membaca pitch absolut | Perubahan sudut dibanding pemasangan awal, uji kedua arah/sumbu |
| P1 | Lengkapi level 0/1/2/3, konfirmasi sampel, hysteresis, kedua hazard | node_sensor.ino:180-202 tidak menghasilkan SIAGA | Peralihan level dapat diulang dan tidak bergetar di sekitar threshold |
| P1 | Perbaiki timestamp dan identitas paket | node_sensor.ino:224 memakai uptime | Waktu penerimaan UTC dari gateway/server, sequence/session, dan deduplikasi |
| P1 | Kalibrasi ADC baterai | node_sensor.ino:103-109 memakai raw x 3,3 | analogReadMilliVolts + attenuation/averaging/rasio terukur; persen hanya estimasi |
| P1 | Tangani internet putus dan reconnect | Belum ada uploader/antrian | LoRa/LCD/alarm tetap hidup; antrean terbatas dipulihkan tanpa duplikasi |
| P1 | Pakai lokasi/jumlah node dan status gateway nyata | firebase_node_repository.dart:69-70; settings_providers.dart:8-18 | Tidak ada ONLINE, 915MHz, empat node atau koordinat fiktif di mode live |
| P1 | Auth, role, rules, validasi schema dan audit command | Belum ada konfigurasi rules/backend terversi | Pembaca/operator/perangkat dibatasi; PIN lokal 1234 bukan pengaman backend |
| P1 | Betulkan test dan dokumentasi yang bertentangan | widget_test.dart:74; PRD/diagram 915MHz/heat interrupt/konsensus | Test hijau; klaim sesuai fitur dan hasil ukur |

Untuk demo, node dapat memakai sampling berulang pendek/continuous terlebih dahulu; ukur daya setelah alur fungsional stabil. **Jangan mempertahankan tidur enam jam untuk deteksi api.** MPU motion interrupt juga tidak membuktikan semua pergeseran lereng yang sangat lambat akan memicu wake. Sampling periodik tetap dibutuhkan. Konfigurasi interrupt harus menyesuaikan latch, polaritas dan clear status dengan level wake. [Contoh Adafruit MPU6050](https://github.com/adafruit/Adafruit_MPU6050/blob/master/examples/motion_detection/motion_detection.ino).

Kendali sirine node yang tidur perlu RX window/jadwal polling atau node aktif selama demo. Tetapkan batas latensi perintah dan expiry; jangan menampilkan "sirine aktif" hanya karena penulisan database berhasil. Gunakan command ID, target node, action, durasi terbatas, expiry, hasil eksekusi dan ACK. Tombol Broadcast juga perlu penerima/pengiriman nyata; saat audit hanya menampilkan SnackBar.

FCM memerlukan pengirim terpercaya dengan kredensial server di backend, bukan di APK atau ESP32. Pilih hosting/backend sesuai akun yang tersedia. Listener lokal saat app terbuka saja belum memenuhi uji notifikasi background. Audit ini tidak menyimpulkan rules cloud saat ini terbuka; yang belum ditemukan adalah rules dan setup deployment yang terversi.

Kontrak alert juga perlu dibenahi: dashboard_providers.dart:51 memperlakukan setiap alert unresolved sebagai AWAS tanpa membaca level, sedangkan roadmap mengusulkan alert mulai SIAGA. AlertModel memakai confirmed_at berbentuk string ISO, telemetri memakai epoch detik, dan command memakai ServerValue.timestamp (milidetik). Pilih format eksplisit per field dan konversi yang diuji. isOnline saat ini memakai batas delapan jam (sensor_node.dart:59); untuk demo sampling pendek, indikator data kedaluwarsa perlu mengikuti interval yang benar, bukan tetap delapan jam.

Pilih **Flutter Android sebagai aplikasi demo utama**. Web root masih prototipe dengan data/simulasi statis. app.js:912-915 dan 936-943 juga menghapus pendingAction saat menutup modal PIN sebelum aksinya dibaca; export PDF pada 985-987 baru toast/log. Jika web ikut dijanjikan sebagai produk, integrasi dan bug itu masuk lingkup tambahan. Simulator Flutter juga perlu pemilihan mode yang benar: mengubah mockFallback saat stream aktif RTDB tidak memperbarui stream live. Satu node fisik boleh didemokan, tetapi konsensus beberapa node belum dapat diklaim sudah terbukti tanpa implementasi dan bukti terpisah.

## 6. Berkas yang perlu dibuat atau diselesaikan

Gunakan nama yang sudah direncanakan pada ROADMAP_DOKUMEN.md agar tidak membuat dua spesifikasi berbeda. File pendukung boleh digabung jika isinya tetap jelas.

| Urutan | Berkas / keluaran | Isi minimum |
| --- | --- | --- |
| 1 | docs/00_SPEC_FREEZE.md | Board, band radio, jumlah node fisik, interval sampling/TX, level, alarm, sasaran latensi, target HP |
| 2 | Revisi docs/PINOUT_V2.md dan tandai pinout.md lama | Satu pinmap aktif, level shifter, skema daya lengkap dan koreksi audit ini |
| 3 | docs/01_BOM_FINAL.md | Qty, dimiliki/belum, rating, pilihan modul, stok, biaya aktual; hindari harga dugaan |
| 4 | docs/05_DATA_CONTRACT.md | Payload berversi, latest/history/alerts, metadata, received_at, validitas sensor, command/ACK, units dan contoh nyata |
| 5 | docs/04_FIRMWARE_SPEC.md + konfigurasi build | State node/gateway, profil board, versi dependency, error/retry, alarm dan perintah |
| 6 | Konfigurasi Firebase/backend | Rules, schema validation, auth/perangkat/operator, indeks history, pengirim notifikasi, contoh konfigurasi tanpa secret |
| 7 | docs/08_CALIBRATION.md | Baseline sudut, soil relatif, baterai terhadap multimeter, suhu, flame; catat per unit |
| 8 | docs/03_ASSEMBLY_GUIDE.md | Urutan rakit, skema, foto hasil nyata, konektor, pemasangan box/MPU/shield |
| 9 | docs/02_POWER_BUDGET.md | Arus terukur tiap mode, energi harian, kapasitas efektif, panel, lama alarm, recharge dan batas suhu |
| 10 | docs/06_TEST_PLAN_RESULTS.md | Skenario, versi firmware/app, tanggal, target, hasil, log dan bukti foto/video |
| 11 | docs/07_DEMO_SCRIPT.md + portfolio + APK | Demo kejadian fisik sampai HP, skenario gangguan, cara instal dan menjalankan |
| 12 | Revisi PRD/diagram/blueprint + panduan pengguna | Sesuai barang dan fitur nyata; simulasinya diberi label; batas penggunaan jelas |

Persentase soil hasil pemetaan dua titik adalah indeks kelembapan relatif, belum otomatis kadar air volumetrik atau kejenuhan tanah ilmiah. Threshold demo harus disebut parameter prototipe; penetapan peringatan operasional warga memerlukan validasi lapangan dan ahli terkait.

## 7. Urutan dari awal sampai akhir dengan gerbang lulus

Jadwal berikut adalah usulan untuk tim, bukan janji durasi. Proposal lokal mencatat pengumpulan **19 Oktober 2026 pukul 23.59**; pastikan informasi terakhir dari panitia. Sediakan buffer sebelum tanggal tersebut.

| Tahap | Usulan tanggal | Pekerjaan | Lulus jika |
| --- | --- | --- | --- |
| A | 7-8 Okt | Kunci scope/board/data; inventaris; ukur suplai; uji tiap sensor | Dua MCU tersedia, rail benar, seluruh sensor/radio terdeteksi tanpa reset |
| B | 8-10 Okt | Firmware node aktif; baseline; alarm; LoRa dan LCD | Data berubah karena sensor fisik; alarm bekerja saat WiFi mati; 100 paket tercatat |
| C | 10-12 Okt | Gateway uploader + waktu + latest/history/alerts; app live | Nilai, unit, node, timestamp dan grafik cocok dengan log paket yang sama |
| D | 12-14 Okt | Backend FCM; command/ACK; status offline/error; aturan akses | HP menerima alert background; sirine ON/OFF terkonfirmasi; perintah salah ditolak |
| E | 14-16 Okt | Rakitan final; baterai/surya; pengukuran dan uji gangguan | Tidak brownout saat TX+alarm; charge berfungsi; berjalan 24 jam dengan log |
| F | 17-18 Okt | Latihan demo, video, portfolio, APK dan backup | Demo lengkap dapat diulang dari cold boot; semua klaim punya bukti |

Pembagian kerja: **tim hardware** merakit, mengukur dan memotret; **aku dapat mengerjakan firmware, backend, aplikasi, alat bantu uji dan dokumentasi** berdasarkan hardware/data yang dikonfirmasi; **bersama** memvalidasi hasil pada board dan HP. Pembelian, wiring, pengukuran, kalibrasi fisik dan pemasangan tidak dapat dibuktikan dari kode saja.

## 8. Checklist penerimaan demo

Angka berikut adalah sasaran prototipe yang perlu disepakati dan diukur, bukan jaminan kinerja saat audit.

- [ ] Cold boot node/gateway berhasil berulang kali, tanpa relay menyala tidak sengaja.
- [ ] Uji tilt pada dua sumbu, soil kering/basah, suhu/RH, flame, dan baterai menghasilkan perubahan yang masuk akal dan tercatat.
- [ ] Semua level yang dijanjikan dapat dipicu dan dipulihkan dengan skenario terdokumentasi.
- [ ] Waktu respons dicatat dari kejadian fisik, terpisah dari waktu setelah sampel tersedia. Target awal app/alert <= 5 detik pada jaringan demo, disesuaikan interval sampling.
- [ ] Motion wake dan timer wake lulus setelah deep sleep; uji kebakaran dilakukan ketika node tidak bergerak.
- [ ] Sedikitnya 100 paket diuji; target awal >= 95% diterima pada jarak demo yang dicatat. CRC gagal ditolak; duplikasi tidak membuat alert berulang.
- [ ] Paket yang sama dapat dilacak dari Serial node, gateway, latest/history, sampai tampilan aplikasi dengan identitas dan waktu benar.
- [ ] Notifikasi diuji saat foreground, background dan layar terkunci; izin dan kegagalan pengiriman terlihat.
- [ ] Command sirine ON/OFF memiliki target, expiry, ACK dan timeout; uji gateway/node tidak tersedia.
- [ ] Sensor dicabut, WiFi putus, gateway mati dan database ditolak menghasilkan UNKNOWN/OFFLINE/ERROR; tidak menampilkan AMAN baru dari data lama.
- [ ] Saat internet putus, alarm lokal dan penerimaan LoRa tetap bekerja; antrean pulih dengan batas penyimpanan yang jelas.
- [ ] Baterai penuh dan mendekati cutoff diuji bersama TX+alarm; catat tegangan rail dan suhu regulator/charger.
- [ ] Charge siang, operasi malam, dan uji 24 jam selesai sebelum mengklaim daya mandiri; tidak menyimpulkan 120 hari dari deep-sleep chip saja.
- [ ] Rakitan final, shielding sensor dan perlindungan air diuji. Uji siram sederhana tidak sama dengan sertifikasi IP65.
- [ ] Test otomatis lulus, APK release dapat diinstal pada HP demo, prosedur startup dan backup tersedia.

## 9. Hasil verifikasi software pada audit

| Pemeriksaan | Hasil | Batas kesimpulan |
| --- | --- | --- |
| Review struktur paket/CRC dan pinmap | Selesai | Verifikasi statis; bukan bukti transmisi fisik |
| flutter analyze --no-pub | 30 temuan kategori info; tidak ada error/warning analyzer; exit 1 | Masih ada deprecated API/style; bukan konfirmasi APK release berhasil dibangun |
| flutter test --no-pub --timeout 25s | **8 lulus, 1 gagal** | Test "Repository streams all initial nodes and aggregates" pada test/widget_test.dart:74 gagal core/no-app: provider default Firebase belum di-init/di-override dalam test |
| Compile/upload firmware | Belum dilakukan | arduino-cli dan pio tidak ditemukan pada PATH saat audit |
| Uji board/LoRa/daya/Firebase cloud/FCM fisik | Belum dilakukan | Memerlukan perangkat, konfigurasi akun, serta bukti log/pengukuran |

Hasil audit bukan pernyataan siap pakai untuk peringatan keselamatan warga. Target sesi ini adalah memastikan pekerjaan demo terdefinisi dan dapat diuji hingga tuntas.
