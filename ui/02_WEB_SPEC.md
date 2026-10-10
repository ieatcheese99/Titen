# TITEN — Spesifikasi Web Monitoring dan Operasi

Versi dokumen: 1.0 · 7 Oktober 2026 · Bahasa UI: Indonesia · Zona tampilan awal: Asia/Jakarta.
Status: spesifikasi target siap dipecah menjadi pekerjaan implementasi; bukan pernyataan fitur telah berjalan.
Rujukan visual: [01_DESIGN_SYSTEM.md](01_DESIGN_SYSTEM.md). Perilaku lintas layar: [04_RESPONSIVE_MATRIX.md](04_RESPONSIVE_MATRIX.md). Pasangan native: [03_APP_FLUTTER_SPEC.md](03_APP_FLUTTER_SPEC.md).

## 1. Tujuan, pengguna, dan batas lingkup

Web membantu operator melihat seluruh perangkat, menelusuri perubahan sensor, memeriksa kegagalan pengiriman, dan mengaudit tindakan. Jalur minimum demo lomba adalah satu node fisik → LoRa → gateway → Firebase Realtime Database (RTDB) → tampilan data asli. Perangkat tambahan hanya muncul setelah terdaftar; empat node contoh bukan bukti empat node fisik.

| Persona | Pekerjaan utama | Informasi pertama | Aksi yang dibutuhkan |
| --- | --- | --- | --- |
| Operator posko | Memeriksa kejadian dan kesehatan pengiriman | Alert aktif, umur data, node yang belum melapor | Buka detail, akui alert, kendalikan alarm bila berwenang |
| Engineer monitoring | Menemukan sumber gangguan | Log, identitas paket, versi konfigurasi, waktu penerimaan | Filter, bandingkan riwayat, ekspor, lihat kalibrasi |
| Penilai demo/pembaca | Memahami alur tanpa mengubah perangkat | Mode sumber, topologi, nilai dan asal data | Navigasi, lihat bukti dan status implementasi |
| Administrator | Mengelola akses dan registri | Role, perangkat terdaftar, audit perubahan | Ubah metadata, hak akses; konfigurasi hardware hanya jika didukung |

Lingkup dokumen ini mencakup frontend web, kontrak adapter, otorisasi yang dibutuhkan, serta kriteria penerimaan. Desain rangkaian, charger, regulator, dan perhitungan power ditunda sesuai keputusan pengguna. Baterai boleh ditampilkan jika ada pembacaan dengan asal dan validitas jelas; pembacaan belum tersedia ditulis `—`.

Keberhasilan demo: perubahan dari sensor fisik dapat ditelusuri ke satu paket dan waktu penerimaan, tampilan tidak menyatakan aman saat data hilang, dan aksi perangkat mempunyai hasil eksekusi yang dapat dibuktikan. Grafik indah, animasi, atau toast sukses tidak menggantikan bukti tersebut.

## 2. Kondisi repository dan keputusan arsitektur

| Temuan kode saat spesifikasi dibuat | Dampak terhadap implementasi |
| --- | --- |
| Root `index.html`, `index.css`, `app.js` adalah prototipe visual dengan simulasi dan status statis | Jangan memperlakukan layar root sebagai dashboard produksi atau sumber telemetri |
| `titen_app/` adalah Flutter; dependensi RTDB, FCM, Riverpod, GoRouter, fl_chart sudah tercantum | Menjadi acuan domain dan kontrak bersama; bukan bukti integrasi backend selesai |
| Gateway membaca paket packed 16 byte, memvalidasi CRC16, lalu mencetak JSON ke Serial/LCD | Uploader WiFi/RTDB, registry gateway, timestamp server, dan history masih pekerjaan backend/firmware |
| Firmware node menetapkan `NODE_ID=1`; radio node/gateway 433 MHz, SF10, BW 125 kHz | Ini konfigurasi kode, bukan frekuensi terukur, kualitas radio, atau keberhasilan paket fisik |
| `watchTelemetryHistory()` Flutter mengambil mock; parser mempunyai fallback angka/lokasi/status | Jangan menyalin fallback itu ke adapter web; kontrak nullable harus diperbaiki bersama |
| Belum ditemukan implementasi broker MQTT, server WebSocket, ACK command, atau konfigurasi pin remote | Tidak tampilkan koneksi MQTT aktif atau tombol hardware seolah sudah berfungsi |

Sumber lokal: [audit](../docs/AUDIT_PINOUT_DAN_RENCANA_DEMO.md), [node](../firmware/node_sensor/node_sensor.ino), [gateway](../firmware/gateway_node/gateway_node.ino), [repositori RTDB](../titen_app/lib/features/dashboard/data/repositories/firebase_node_repository.dart), [model node](../titen_app/lib/features/dashboard/data/models/sensor_node.dart), [pubspec](../titen_app/pubspec.yaml).

### 2.1 Jalur target dan pemisahan lapisan

```text
Sensor fisik → payload LoRa → gateway + validasi CRC
  → uploader terautentikasi → normalisasi/validasi backend
  → RTDB: latest, history, alerts, commands, audit, registry
  → RtdbTelemetryAdapter → store domain → selector → komponen UI

Fixture berlabel → DemoTelemetryAdapter → store DEMO terpisah
Cache terakhir → CacheAdapter → tampilan OFFLINE · cache

MqttEventAdapter / WebSocketEventAdapter: future, capability=false
```

React + TypeScript dengan komponen shadcn/ui, Tremor, dan Lucide adalah **opsi target web yang dipilih untuk spesifikasi ini**, belum terpasang pada repository. Membuat proyek web baru dan migrasi root adalah pekerjaan tersendiri; jangan mengganti Flutter atau memasukkan library React ke build Flutter. Adapter domain harus dapat dipakai ulang secara konseptual tanpa ketergantungan UI.

Listener RTDB adalah implementasi awal stream; SDK menyediakan listener perubahan data. Subscribe pada path/query terbatas dan lepaskan listener ketika lingkup layar berubah. Keberhasilan write hanya membuktikan database menerima perubahan, bukan sirine berbunyi. [Firebase: read/write web](https://firebase.google.com/docs/database/web/read-and-write).

### 2.2 Kontrak adapter frontend

| Antarmuka target | Keluaran/perilaku |
| --- | --- |
| `watchRegistry(scope)` | Metadata resmi, keanggotaan gateway/node, capabilities, jadwal laporan |
| `watchLatest(scope)` | Snapshot nullable per node; state loading/empty/error eksplisit |
| `queryHistory(nodeId, range, cursor, limit)` | Halaman data dengan cursor stabil; tidak menggunakan fixture dalam LIVE |
| `watchAlerts(scope, cursor)` | Alert terurut, status acknowledgment dan resolution terpisah |
| `watchEvents(filters, cursor)` | Event domain normalisasi; kolom `transport=rtdb` untuk sumber awal |
| `requestCommand(command)` / `watchCommand(id)` | Hanya aktif bila backend + firmware + role mendukung kontrak command |
| `proposeConfig(change)` | Capability-gated; tidak aktif pada firmware sekarang |
| `connectionState()` | State koneksi SDK/cloud; bukan kesehatan gateway atau node |

Adapter mengembalikan error bertipe `permission_denied`, `unavailable`, `invalid_schema`, `unsupported_capability`, atau `expired_session`. Komponen tidak mengubah error menjadi array kosong atau angka nol. Refresh mengambil ulang data; refresh tidak mengirim perintah hardware.

## 3. Model state yang wajib konsisten

### 3.1 Sumber, koneksi, umur data, dan bahaya

Empat dimensi berikut harus disimpan terpisah. Badge tidak boleh menggabungkan semuanya menjadi satu lampu hijau/merah.

| Dimensi | Nilai | Makna UI |
| --- | --- | --- |
| Sumber | `live`, `demo` | `LIVE` atau `DEMO`; fixture hanya masuk DEMO; cache bukan jenis sumber ketiga |
| Koneksi cloud | `online`, `reconnecting`, `offline`, `unknown` | Hubungan browser/adapter ke cloud; label tekstual selalu ada |
| Freshness telemetri | `fresh`, `stale`, `missing`, `unknown` | Umur laporan node berdasarkan kontrak jadwal registry |
| Bahaya | `0`, `1`, `2`, `3`, `null` | Aman, Waspada, Siaga, Awas, atau Belum diketahui |

Sumber `live` berarti adapter live dipilih, bukan data dijamin terbaru. Browser dapat online sementara node belum melapor. Browser tanpa jaringan masih dapat menampilkan `DEMO` dari fixture, dengan indikator koneksi cloud terpisah. Cache mempunyai metadata `cached_at` dan source asal; badge `OFFLINE · cache LIVE` adalah presentasi koneksi, bukan enum source baru. Tidak ada perpindahan otomatis LIVE → DEMO saat data kosong atau gagal.

Freshness memakai `R=registry.expected_report_interval_ms` dan `J=registry.delivery_grace_ms`, bukan interval sampling internal atau nilai tetap delapan jam. `age=server_now−received_at` setelah offset waktu server tervalidasi. Heartbeat gateway mempunyai jadwal dan freshness sendiri.

| Kondisi | Hasil |
| --- | --- |
| `R`, `J`, waktu server, atau `received_at` tidak sah/tersedia | `unknown`; tampilkan alasan |
| `age <= R+J` | `fresh` |
| `R+J < age <= 3R+J` | `stale` |
| `age > 3R+J` | `missing` |
| Clock skew besar atau timestamp dari masa depan | `unknown` + event kualitas waktu; jangan menjepit diam-diam menjadi fresh |

Istilah node **offline** hanya dipakai bila ada status offline/last-will eksplisit, atau kontrak jadwal laporan yang sah membuktikan laporan terlewat dengan mempertimbangkan tidur terencana dan maintenance. Tanpa bukti itu gunakan “Laporan belum diterima”. Firmware sekarang masih tidur 21.600 detik dan belum memberi kontrak heartbeat yang tervalidasi; jangan mengubah label menjadi online hanya karena konfigurasi tersebut ada.

Level 0 hanya ditampilkan sebagai “Aman” ketika nilai valid, sumber jelas, dan freshness fresh. Jika stale, tampilkan “Terakhir: Aman · data kedaluwarsa”, dengan warna status umur data; jangan menampilkan AMAN hijau sebagai kondisi terkini. Alert unresolved tidak otomatis berarti Awas: baca level alert yang tersimpan.

### 3.2 Mode data dan validitas per metrik

- LIVE hanya memakai record tervalidasi dari integrasi asli; payload yang tidak dapat dibuktikan valid diberi quality flag.
- DEMO selalu mempunyai badge persisten, banner, serta identitas fixture; aksi hanya memodifikasi simulator.
- OFFLINE memakai cache bertanggal dan label asal LIVE/DEMO; command hardware selalu diblokir tanpa antrean replay.
- Loading memakai skeleton ukuran tetap; kosong menampilkan instruksi setup; error menampilkan alasan dan retry.
- Null berbeda dari nol: nol tetap boleh ditampilkan jika benar-benar dikirim sensor valid.
- Firmware DHT sekarang mengisi angka fallback saat gagal. Sampai firmware mengirim flag validitas atau adapter dapat memverifikasi, label kualitas DHT “Belum terverifikasi”; jangan menyebutnya pembacaan sehat.
- Persen soil adalah indeks relatif hasil kalibrasi dua titik, bukan klaim kadar air volumetrik. Nilai tilt saat ini pitch absolut; label “Perubahan terhadap baseline” hanya setelah kalibrasi baseline benar-benar didukung.

## 4. Information architecture dan shell

### 4.1 Route dan deep link

| Route target | Judul | Konten dan akses |
| --- | --- | --- |
| `/overview` | Ringkasan | Alert, kualitas data, topologi, daftar node; semua pembaca |
| `/nodes` | Node | Tabel/grid, filter, detail; pembaca sesuai scope |
| `/nodes/:nodeId` | Detail node | Telemetri, history, event, konfigurasi; ID numerik, tidak menebak node dari digit nama |
| `/gateways` | Gateway | Registry, koneksi, uplink, node terhubung; pembaca |
| `/gateways/:gatewayId` | Detail gateway | Data aktual, konfigurasi, event; ID string persis dari registry |
| `/alerts` | Alert | Kejadian, acknowledgment, resolution, bukti; aksi sesuai role |
| `/analytics` | Analitik | Rentang tanggal, grafik, tabel data, ekspor |
| `/events` | Event & log | DEBUG/INFO/WARN/ERROR, source, transport, correlation |
| `/audit` | Audit aktivitas | Perubahan akses/metadata/config/command; engineer/admin sesuai scope |
| `/settings` | Pengaturan | Profil, tema, zona waktu, registry dan akses sesuai role |

Filter tersimpan di URL: `node`, `gateway`, `from`, `to`, `severity`, `hazard`, `freshness`, `view`; gunakan encoding standar. Route langsung harus melewati autentikasi dan otorisasi lagi. Node tidak ditemukan menampilkan 404 domain, bukan membuat node default 1.

### 4.2 Tata letak desktop

Shell: sidebar 232 px terbuka atau 64 px collapsed; topbar 56 px; main canvas lebar tersedia dengan padding 24 px. Sidebar berisi brand kecil, kelompok Monitor, Operasi, Administrasi, dan profil di bawah. Tidak memakai frame HP, notch, status bar seluler palsu, atau hero marketing pada web.

Overview memakai grid 12 kolom, gap 16 px. Baris awal: judul+mode, banner kualitas data, ringkasan jumlah terdaftar/fresh/stale/missing. Baris tengah: topologi 7 kolom dan daftar alert 5 kolom. Baris berikutnya: tabel node penuh; stream event dapat dibuka sebagai panel bawah 240–360 px. Pada kanvas sempit, topologi dan alert bertumpuk sebelum tabel.

Perhitungan jumlah hanya dari registry dan data sesuai scope. Jika registry belum tersedia, “Node terdaftar: —”; jika snapshot registry sukses dan kosong, “0 node terdaftar”. Angka total normal tidak boleh memasukkan node unknown atau sensor invalid. Menandai kesenjangan data lebih penting daripada mengisi ruang dengan KPI fiktif.

### 4.3 Topologi, tabel, grid, dan detail

Topologi adalah diagram hubungan node → gateway → cloud, **bukan peta geografis**. Edge hanya untuk hubungan registry atau observasi paket yang sah; edge putus-putus menandai hubungan diketahui tetapi belum terbukti menerima paket. Tanpa lokasi, tidak membuat koordinat perkiraan. Pan/zoom dan “Pas ke tampilan” tersedia; alternatif tabel selalu tersedia untuk keyboard dan pembaca layar.

Daftar node default berupa tabel: identitas, gateway, bahaya, umur data, kualitas sensor, tilt, soil, suhu, RH, RSSI/SNR terakhir, baterai bila tersedia, aksi detail. Kolom unit tertera pada header; angka tabular rata kanan. Pilihan grid memakai isi yang sama dan cocok untuk jumlah node kecil; view tidak mengganti semantics atau menyembunyikan data stale.

Klik identitas membuka detail drawer tanpa kehilangan filter/scroll. Desktop drawer 480 px atau maksimum 45% viewport; tautan “Buka halaman penuh” memakai route detail. Tab: Ringkasan, Riwayat, Event, Kalibrasi, Konfigurasi. Breadcrumb, nama node, mode, freshness, waktu penerimaan, dan tombol tutup tetap terlihat.

Kalibrasi pinout berarti **memeriksa profil pin dan kalibrasi sensor**, bukan slider bebas yang mengubah sambungan fisik. Tabel menampilkan board, fungsi, GPIO, source dokumen, versi firmware dan perbedaan target-versus-reported. Baseline tilt dan soil mempunyai nilai/datum/operator/bukti terpisah. Firmware sekarang belum memiliki round trip config/ACK; tab dapat menjelaskan langkah manual dan membaca spesifikasi, tetapi “Kirim ke perangkat” disabled.

Config gateway memisahkan metadata registry dari parameter radio/firmware. Nama/lokasi resmi dapat diedit oleh admin dengan audit. Band 433 MHz/SF10/BW 125 kHz tampil “Dikonfigurasi dalam kode; belum dibaca balik”. Jangan menunjukkan 915 MHz, jumlah empat node, SSID, atau uptime yang tidak tersedia. Secret WiFi tidak disajikan ulang dari database ke browser.

## 5. Katalog komponen web

Semua warna, typography, border, fokus, motion, serta kontras mengikuti token [01_DESIGN_SYSTEM.md](01_DESIGN_SYSTEM.md). `surface.panel` adalah panel zinc/putih sesuai tema; `text.primary` dan `text.secondary` adalah pasangan teks yang diuji; `semantic.*.fg/bg/border` dipakai dengan teks+ikon dan pasangan background masing-masing. Tema awal mengikuti sistem. UI menggunakan Inter; angka teknis JetBrains Mono. Radius tombol 6 px, panel 8 px, drawer/dialog 10 px; border 1 px. Target sentuh kontrol hardware minimum 48×48 CSS px. State Default/Hover atau focus/Active/Disabled/Error/Loading di bawah wajib diimplementasikan, termasuk pada komponen informatif yang tidak dapat diklik. Di bawah 640 px, metadata/log minimum 13 px dan instruksi/error minimum 14 px mengikuti design system; ukuran compact di katalog adalah desktop.

Contoh berlabel **FAKTA KODE** hanya fakta hasil pembacaan kode. **BELUM TERSEDIA** adalah tampilan null yang jujur, bukan rekaman unit. Belum ditemukan capture telemetri fisik terversi; dokumen ini tidak menyebut angka fixture sebagai data nyata.

### WEB-01 — Sidebar navigasi

- **Fungsi:** berpindah route, menyimpan preferensi collapsed per pengguna, menampilkan scope dan role.
- **Visual:** `surface.panel`, `text.secondary`, `border.subtle`; item minimum 48 px pada desktop/touch, radius 6 px, Inter 14 px; ikon Lucide 18 px.
- **Default:** route aktif mempunyai marker dan teks `text.primary`; **Hover/focus:** background `surface.subtle`, focus ring; **Active:** pressed tanpa glow.
- **Disabled:** route yang tak tersedia diberi alasan jika relevan, administrasi tanpa hak disembunyikan; **Error:** scope gagal memakai teks+retry; **Loading:** skeleton metadata scope.
- **Contoh jujur:** “Node” menuju daftar; label scope “Registry belum tersedia”, bukan “4 node online”.

### WEB-02 — Topbar, sumber data, dan breadcrumb

- **Fungsi:** memberi orientasi halaman, mode data, tema, zona waktu, pencarian identitas.
- **Visual:** `surface.canvas`, border bawah `border.subtle`, Inter 14 px/metadata 12 px; badge mono 11 px radius 6 px, tinggi topbar 56 px.
- **Default:** mode dan koneksi tampil terpisah; **Hover/focus:** tooltip mode menjelaskan provenance; **Active:** menu/combobox terbuka dengan ring.
- **Disabled:** pergantian scope saat transaksi konfirmasi berlangsung; **Error:** sesi kedaluwarsa membuka reauth tanpa mengirim aksi; **Loading:** skeleton nama scope, badge tetap terlihat.
- **Contoh jujur:** `LIVE · RTDB dipilih` + `Koneksi: belum diverifikasi`; mode LIVE sendiri tidak mengklaim gateway online.

### WEB-03 — Banner koneksi dan kualitas data

- **Fungsi:** menjelaskan reconnect, latency tinggi, cache, permission error, dan timestamp bermasalah.
- **Visual:** `surface.panel`, border semantik `semantic.warning.border`/`semantic.critical.border`; Inter 13 px, ikon 18 px, radius 6 px; tak mengandalkan warna.
- **Default:** tidak tampil bila koneksi normal dan tanpa isu; **Hover/focus:** tombol detail/retry mendapat ring; **Active:** retry menampilkan progress.
- **Disabled:** retry ketika proses berlangsung; **Error:** pesan ringkas + kode dan salin detail; **Loading:** “Menghubungkan…” dengan status statis yang terbaca.
- **Contoh jujur:** “Belum ada waktu penerimaan yang valid. Umur data tidak dapat dihitung.”

### WEB-04 — Ringkasan cakupan dan freshness

- **Fungsi:** menghitung node terdaftar, fresh, stale, missing, unknown, dan alert sesuai scope.
- **Visual:** panel datar `surface.panel`, `text.primary`, angka mono 24 px, label Inter 12 px; radius 8 px, gap 16 px, tanpa grafik dekoratif.
- **Default:** angka hanya dari snapshot sah; **Hover/focus:** kategori dapat membuka filter; **Active:** filter terpilih ditandai teks.
- **Disabled:** drilldown bila registry tidak tersedia; **Error:** `—` + alasan; **Loading:** skeleton angka, bukan angka 0 sementara.
- **Contoh jujur:** “ID node pada firmware: 1” berbeda dari “Node terdaftar: — / Laporan diterima: —”; ID bukan jumlah node fisik yang telah diverifikasi.

### WEB-05 — Topologi perangkat

- **Fungsi:** memperlihatkan jalur hubungan dan titik kegagalan dengan alternatif daftar.
- **Visual:** `surface.panel`, node radius 8 px, border 1 px, garis solid/dashed; Inter 12 px dan ID mono 12 px; label kualitas tidak berupa pulse terus-menerus.
- **Default:** layout deterministik menurut registry; **Hover/focus:** ring pada node dan ringkasan tekstual; **Active:** node terpilih membuka detail.
- **Disabled:** drag bila navigasi keyboard aktif atau reduce-motion; **Error:** registry gagal menampilkan error, edge tak direka; **Loading:** skeleton diagram berlabel struktur.
- **Contoh jujur:** `Node 01 · FAKTA KODE` dengan edge bertanda “Gateway belum diregistrasi”; diagram ini belum bukti perangkat online.

### WEB-06 — Tabel dan grid node

- **Fungsi:** membandingkan node, menyortir, memfilter, dan membuka detail.
- **Visual:** `surface.panel`, header Inter 12 px `text.secondary`, row minimum 48 px desktop/64 px compact, angka mono 13 px, separator 1 px; grid radius 8 px. Kontrol di row tetap memiliki hit area48 tanpa tumpang tindih.
- **Default:** sort freshness/bahaya eksplisit tanpa menggeser baris setiap paket; **Hover/focus:** highlight row; **Active:** selection mempunyai aria-selected dan marker.
- **Disabled:** bulk hardware action tanpa capability/role; **Error:** banner query + data lama berlabel; **Loading:** skeleton row, tidak membuat node placeholder menjadi entitas.
- **Contoh jujur:** `1 | Gateway — | Bahaya belum diketahui | Tilt —° | RSSI — dBm`; ini template untuk node dari kode, bukan telemetri nyata.

### WEB-07 — Kartu telemetri

- **Fungsi:** nilai sensor, unit, kualitas, asal, waktu, dan sparklines yang relevan.
- **Visual:** `surface.panel`, `text.primary`, nilai `type.value` mono 24 px, unit mono 12 px, metadata Inter 12 px, radius 8 px; warna semantik hanya untuk state.
- **Default:** format tilt/suhu satu desimal bila valid, RH/soil/baterai persen sesuai resolusi sumber; **Hover/focus:** reveal waktu dan provenance; **Active:** pilih metrik grafik.
- **Disabled:** drilldown saat tidak ada history; **Error:** `—` + “Sensor tidak valid” tanpa mempertahankan angka palsu; **Loading:** skeleton ukuran nilai tetap.
- **Contoh jujur:** “Suhu udara — °C · Validitas DHT belum terverifikasi”; persentase baterai tidak diisi 100% sebagai default.

### WEB-08 — Grafik riwayat dan sparkline

- **Fungsi:** melihat perubahan waktu dan celah pengiriman, bukan memprediksi bencana dari dekorasi.
- **Visual:** `surface.panel`, grid `border.subtle`, sumbu Inter 11 px/mono 11 px, garis 2 px dengan warna chart dari design system, radius 8 px; tanpa area glow.
- **Default:** sumbu waktu/unit jelas; null menghasilkan gap; **Hover/focus:** tooltip waktu/nilai/quality yang juga dapat diakses keyboard; **Active:** brush/range eksplisit.
- **Disabled:** range tak didukung query; **Error:** tampilkan query gagal tanpa fallback sinus/mock; **Loading:** placeholder sumbu tanpa titik hasil rekaan.
- **Contoh jujur:** “Riwayat belum tersedia untuk Node 1”; snapshot tunggal tampil titik tunggal, tidak digandakan menjadi kurva.

### WEB-09 — Toolbar filter dan rentang waktu

- **Fungsi:** filter node/gateway/bahaya/freshness/level event serta preset tanggal.
- **Visual:** `surface.panel`, field radius 6 px border `border.control`, Inter 14 px; chips mempunyai tombol hapus dan target 48 px pada touch.
- **Default:** preset 24 jam, 7 hari, custom ditawarkan sesuai backend; **Hover/focus:** label/ring jelas; **Active:** filter diterapkan via tombol atau debounced search 250 ms.
- **Disabled:** pilihan capability tak tersedia disertai alasan; **Error:** tanggal akhir sebelum awal diblokir; **Loading:** pilihan registry skeleton tanpa menghapus filter URL.
- **Contoh jujur:** `Node 1` dari kode; gateway `Belum ada di registry`, bukan ID gateway buatan.

### WEB-10 — Stream event dan inspector payload

- **Fungsi:** mengikuti event domain dengan transport asli, severity, correlation, payload tersaring.
- **Visual:** `surface.panel`, baris mono 12 px minimum line-height 18 px, severity teks+ikon; inspector radius 8 px dengan salin JSON, tidak memakai console neon.
- **Default:** label sumber `RTDB events` bila tersedia; **Hover/focus:** baris menampilkan tindakan detail; **Active:** inspector/pause terbuka.
- **Disabled:** tab MQTT/WebSocket menampilkan “Backend belum mendukung”; **Error:** invalid_schema tampil event tanpa dimasukkan ke latest; **Loading:** “Menunggu event” tidak membuat log palsu.
- **Contoh jujur:** `FAKTA KODE · LoRa 433 MHz / SF10 / BW 125 kHz`; bukan event `MQTT CONNECTED` rekaan.

### WEB-11 — Detail drawer node/gateway

- **Fungsi:** menginspeksi konteks lengkap tanpa kehilangan posisi daftar; deep link halaman tersedia.
- **Visual:** `surface.raised`, border kiri, radius 10 px untuk overlay, Inter 14 px, ID mono 13 px; header/footer sticky, konten scroll terpisah.
- **Default:** tab Ringkasan, state independent; **Hover/focus:** tab/tombol mempunyai ring; **Active:** focus trap dan Escape pada drawer tanpa transaksi.
- **Disabled:** tab write tanpa role/capability; **Error:** detail hilang menampilkan “Perangkat tidak ditemukan”; **Loading:** skeleton section dan judul ID tetap.
- **Contoh jujur:** `Node 1 · Board ESP32-S3 N16R8 acuan audit · Versi firmware —`.

### WEB-12 — Inspector kalibrasi dan profil pinout

- **Fungsi:** membandingkan dokumen acuan, konfigurasi dilaporkan, dan status kalibrasi sensor.
- **Visual:** tabel compact `surface.panel`, GPIO mono 13 px, label Inter 12 px, diff marker `semantic.warning.fg` dengan `semantic.warning.bg`; radius 8 px dan border 1 px.
- **Default:** membaca acuan tanpa mengklaim applied; **Hover/focus:** tooltip source/versi; **Active:** memilih sensor menampilkan prosedur dan bukti kalibrasi.
- **Disabled:** kirim profil/baseline karena firmware belum mendukung ACK; **Error:** mismatch ditandai teks; **Loading:** metadata perangkat skeleton terpisah dari acuan statis.
- **Contoh jujur:** `Flame DO: target GPIO7; kode saat ini GPIO3; status mismatch`. UI tidak membuktikan kabel fisik sudah dipindah.

### WEB-13 — Editor konfigurasi gateway

- **Fungsi:** edit metadata berizin dan, kelak, parameter perangkat dengan versioning serta ACK.
- **Visual:** `surface.raised`, field radius 6 px, label Inter 14 px, nilai teknis mono 13 px, footer diff+actions; radius 10 px drawer.
- **Default:** read-only reported/desired terpisah; **Hover/focus:** ring dan hint unit; **Active:** draft lokal memperlihatkan perbedaan, belum applied.
- **Disabled:** write radio/WiFi/pin tanpa capability+role; **Error:** konflik versi meminta reload/merge metadata; **Loading:** skeleton config tanpa mengisi default hardware.
- **Contoh jujur:** “433 MHz · konfigurasi kode”; `applied_version: —`; tombol hardware “Belum didukung firmware”.

### WEB-14 — Kontrol relay/sirine dan command tracker

- **Fungsi:** meminta aksi hardware yang dibatasi durasi, lalu menelusuri hasil sampai perangkat.
- **Visual:** panel `surface.panel`, label Inter 14 px, status mono 12 px, tombol 48 px radius 6 px; aksi memakai `semantic.critical.fg` dengan `semantic.critical.bg` sesuai token, tanpa glow.
- **Default:** status aktuator “Belum diketahui”; **Hover/focus:** tujuan dan konsekuensi jelas; **Active:** membuka konfirmasi target/action/durasi/expiry, bukan langsung mengubah label menjadi ON.
- **Disabled:** offline, stale tak memenuhi kebijakan, role/capability hilang, atau command aktif; **Error:** gagal/expired dengan reason; **Loading:** requested/accepted/executing tetap membedakan progress.
- **Contoh jujur:** “Sirine Node 1 — · Kendali belum didukung”; menulis `commands/siren_test` saja belum membuktikan eksekusi.

### WEB-15 — Daftar alert dan timeline kejadian

- **Fungsi:** memprioritaskan kejadian, melihat level saat kejadian, mengakui, dan menyelesaikan insiden secara terpisah.
- **Visual:** `surface.panel`, label level Inter 12 px + ikon, waktu mono 12 px, border semantik di sisi 4 px; radius 8 px tanpa animasi kedip.
- **Default:** sort kejadian terbaru/keparahan yang dipilih; **Hover/focus:** detail event terbaca; **Active:** acknowledgment meminta catatan jika kebijakan mengharuskan.
- **Disabled:** aksi tanpa role atau backend; **Error:** konflik update memperlihatkan status server; **Loading:** skeleton, query kosong sukses menyatakan tidak ada alert pada range.
- **Contoh jujur:** “Alert belum dapat dimuat” berbeda dari “Tidak ada alert”; level 2 tidak dinaikkan menjadi level 3 karena unresolved.

### WEB-16 — Export CSV/JSON

- **Fungsi:** mengekspor dataset dengan scope/range/quality yang dapat ditelusuri.
- **Visual:** tombol outline `border.control`, `text.primary`, Inter 13 px, ikon Download 18 px, radius 6 px; panel progress memakai mono 12 px.
- **Default:** pilih format dan field; **Hover/focus:** tooltip jumlah hanya jika diketahui; **Active:** job menyatakan range dan snapshot cutoff.
- **Disabled:** belum ada query valid/izin atau sedang export; **Error:** unduhan gagal memberi retry dengan cutoff sama; **Loading:** progress page/record yang diketahui, tidak persentase palsu.
- **Contoh jujur:** “Tidak ada rekaman asli pada rentang ini”; ekspor fixture wajib bernama `DEMO_...` dan metadata `source=demo`.

### WEB-17 — Tabel audit dan detail perubahan

- **Fungsi:** membuktikan siapa melakukan apa, kapan, terhadap target mana, serta hasilnya.
- **Visual:** `surface.panel`, Inter 12 px, ID/waktu/hash mono 12 px, radius 8 px; diff field memakai teks Before/After dan semantik.
- **Default:** log immutable dari backend; **Hover/focus:** buka correlation; **Active:** expand detail memuat payload tersaring.
- **Disabled:** edit/hapus audit tidak tersedia di UI; **Error:** permission/error query bukan log kosong; **Loading:** skeleton row.
- **Contoh jujur:** “Belum ada audit backend terversi”; UI tidak membuat nama operator atau catatan eksekusi fisik.

### WEB-18 — Empty, loading, error, dan recovery panel

- **Fungsi:** menjaga kegagalan dan kekosongan dapat dipahami serta ditindaklanjuti.
- **Visual:** `surface.panel`, `text.primary`/`text.secondary`, ikon 24 px, radius 8 px, padding 24 px; tanpa ilustrasi besar yang mengurangi ruang data.
- **Default:** satu alasan + aksi relevan; **Hover/focus:** CTA ring; **Active:** retry/lihat panduan menunjukkan progress.
- **Disabled:** retry ketika tak berizin, menawarkan masuk ulang; **Error:** request ID tersaring tersedia untuk engineer; **Loading:** skeleton bounded dan teks setelah ambang delay.
- **Contoh jujur:** “Gateway belum terdaftar. Administrator dapat melengkapi registry.”; bukan “Sistem normal”.

## 6. Kontrak data, identitas, waktu, dan kualitas

### 6.1 Field sumber saat ini dan normalisasi target

| Field Serial JSON gateway saat ini | Domain UI target | Unit/aturan |
| --- | --- | --- |
| `node_id` | `node_id` | integer 1–255; fakta konfigurasi sekarang 1; bukan key yang ditebak dari nama |
| Tidak ada | `node_key` | key registry string; target `node_01` memetakan `node_id=1` |
| Tidak ada | `gateway_id` | string wajib dari registry untuk record live; tidak mengarang ID |
| `tilt_deg` | `tilt_deg` | derajat; label pitch absolut sampai baseline tervalidasi |
| `soil_moisture` | `soil_moisture_pct` | persen indeks relatif, bukan VWC |
| `air_temp` | `air_temp_c` | °C; angka fallback firmware bukan pembacaan valid otomatis |
| `air_humidity` | `air_humidity_pct` | %RH; quality wajib |
| `battery_pct` | `battery_pct` | persen estimasi jika tersedia; tidak merancang power di sini |
| `rssi`, `snr` | `rssi_dbm`, `snr_db` | pengukuran penerimaan paket di gateway, bukan sinyal WiFi HP |
| `hazard_type` | `hazard_type` | enum 0/1/2; invalid/null → unknown |
| `status_level` | `hazard_level` | level 0/1/2/3; invalid/null → unknown; jangan memakai nama raw sebagai field domain baru |
| Tidak dicetak ke JSON | `observed_at` | UTC ISO8601 nullable; isi hanya bila clock observasi terbukti sah |
| Tidak ada | `received_at` | UTC ISO8601 wajib dari backend tepercaya |
| Tidak ada | `sequence`, `session_id` | deduplikasi/reset; dibutuhkan perubahan firmware/kontrak |
| Tidak ada | `schema_version`, `quality`, `firmware_version` | target schema_version=2; per-field validity dan provenance |

`timestamp_rtc` ada pada paket binary, tetapi firmware mengisinya dari `millis()/1000` dan gateway tidak mencetaknya dalam Serial JSON. Jangan mengonversinya menjadi tanggal Unix. Backend menambahkan `received_at`; `observed_at=null` sampai waktu node terbukti sah. Tampilan waktu lokal WIB selalu mempunyai tooltip UTC; ekspor memakai UTC dan mencatat zona tampilan terpisah.

Record kanonis live schema_version=2 harus mempunyai identitas terdaftar, waktu penerimaan, dan provenance. `node_key=node_01` adalah key target untuk `node_id=1`, bukan bukti registry sudah dibuat; angka `1` tidak dipakai bergantian sebagai key path. Deduplication key target: `(gateway_id,node_id,session_id,sequence)`; key history tidak boleh hanya `node_id`. Sampai firmware memberi sequence/session, backend wajib mencatat keterbatasan dedupe; UI tidak boleh menjanjikan exactly-once atau menghitung packet loss tanpa denominator yang sah.

Contoh **template inspeksi tanpa capture fisik**; null bukan payload serial yang berhasil direkam:

```json
{
  "evidence_kind": "configuration_inspection_only",
  "node_id": 1,
  "configured_radio": { "frequency_hz": 433000000, "sf": 10, "bandwidth_hz": 125000 },
  "tilt_deg": null,
  "soil_moisture_pct": null,
  "air_temp_c": null,
  "air_humidity_pct": null,
  "rssi_dbm": null,
  "snr_db": null,
  "battery_pct": null,
  "hazard_type": null,
  "hazard_level": null,
  "observed_at": null,
  "received_at": null
}
```

Template di atas **bukan record kanonis live**: gateway belum diketahui, belum ada waktu server atau capture. Gunakan hanya untuk desain state “belum tersedia”; jangan memasukkannya ke RTDB latest. Setelah capture dibuat, contoh data nyata menggantikan template dengan bukti paket/timestamp serta penyamaran data sensitif bila perlu.

### 6.2 Struktur RTDB target dan query

| Path konseptual | Data | Dependensi |
| --- | --- | --- |
| `registry/gateways/{gateway_id}` | identitas, capabilities, board, firmware, jadwal heartbeat | registry/admin + attestation perangkat |
| `gateway_status/{gateway_id}` | heartbeat, koneksi, waktu laporan gateway; berbeda dari node freshness | uploader dan heartbeat tervalidasi |
| `registry/nodes/{node_key}` | node_id numerik, nama/lokasi resmi, gateway, jadwal laporan R/J, profil kalibrasi | setup registry; lokasi nullable |
| `nodes/{node_key}/latest` | snapshot kanonis tervalidasi schema_version=2 | normalizer uploader |
| `history/{node_key}/{event_id}` | record immutable dengan gateway_id dan received_at | indeks/query/retensi |
| `alerts/{alert_id}` | level, hazard, lifecycle, correlation, bukti | engine alert backend |
| `commands/{command_id}` | request/state terkontrol, expiry, actor; result dan device_ack embedded | backend+firmware downlink/ACK |
| `events/{event_id}`, `audit/{audit_id}` | observabilitas dan tindakan | writer backend, scope dan retention |

Ini path target v2 dan belum dideploy. Bentuk flat `nodes/node_01` saat ini adalah legacy v1 yang hanya dibaca melalui adapter legacy; record v2 memakai `nodes/node_01/latest`. Adapter menormalisasi epoch detik legacy dan timestamp server milidetik hanya ketika unit dan asalnya diketahui; uptime bukan tanggal. Buat migration/adapter eksplisit; jangan menggandakan kontrak tanpa versi atau memuat seluruh history root ke browser.

Gunakan query waktu/key dengan cursor yang stabil dan indeks yang sesuai. RTDB menyediakan ordering serta limit/range query; kombinasi query harus diuji terhadap struktur aktual dan rules. Cursor pagination memakai tuple waktu+key agar record dengan waktu sama tidak hilang; strategy implementasi harus memakai operasi yang tersedia pada SDK yang dipilih. [Firebase: lists/query web](https://firebase.google.com/docs/database/web/lists-of-data).

## 7. Aksi hardware, konfigurasi, dan audit

### 7.1 Lifecycle command

State target: `requested → accepted → executing → succeeded | failed`; request dapat failed/expired/cancelled sebelum diterima. Accepted dapat failed/expired jika belum mulai; cancelled hanya bila backend/perangkat mengonfirmasi belum dieksekusi dan capability pembatalan tersedia. Setelah executing, hasil yang belum datang bukan otomatis expired atau failed. Transisi divalidasi server dan mencatat actor/waktu. `accepted` adalah penerimaan permintaan, transport ACK adalah pengiriman, sedangkan `succeeded` memerlukan hasil eksekusi dari perangkat. UI memberi label bukti tersebut secara berbeda; “Hasil belum diketahui” adalah presentasi keterbatasan bukti, bukan enum command baru.

Payload minimum: `command_id`, target `node_id`/`gateway_id`, action, parameter terbatas, `requested_at`, `expires_at`, actor dari sesi server, `expected_config_version` bila relevan, dan idempotency key. Result: state, `executed_at` bila valid, reason, `reported_actuator_state`, firmware/session/correlation. ACK bahwa pin relay diperintah hanya membuktikan output GPIO menurut firmware; klaim sirine benar-benar berbunyi memerlukan sensor/observasi terpisah.

Sebelum kirim: validasi role server, capability perangkat, koneksi, versi, jadwal penerimaan, serta expiry. Konfirmasi menampilkan target fisik, ON/OFF, durasi, dan batas berlaku. State switch mengikuti reported state terakhir; jangan optimistic ON. Double-click tidak membuat dua command. Membuka/menutup konfirmasi tidak menghapus pending action sebelum submit dibaca.

Saat offline: blokir command, jangan menyimpan hardware command ke antrean lokal atau me-replay setelah reconnect. Command yang expire tidak boleh dijalankan perangkat ketika baru tersambung. Jika browser kehilangan koneksi setelah submit, tampilkan “Hasil belum diketahui”, lalu query command ID saat reconnect; jangan otomatis mengirim ulang. Tombol OFF tetap meminta jalur dan bukti yang sama, dengan kebijakan prioritas backend yang diuji.

### 7.2 Kalibrasi, pinout, dan perubahan parameter

Perubahan hardware/config membutuhkan capability spesifik (`remote_config`, `pin_profile`, `calibration_write`), otorisasi server, desired version, applied version, validasi profil board, serta ACK hasil perangkat. Persyaratan ini belum didukung firmware sekarang: tampilkan inspector dan prosedur manual; kontrol kirim disabled dengan alasan.

Draft kalibrasi menyimpan operator, metode, nilai sebelum/sesudah, orientasi MPU, unit, waktu, versi, serta bukti uji. “Simpan catatan” hanya menyimpan metadata; jangan menamakannya “Kalibrasi selesai” atau “Terapkan” bila perangkat belum menyimpan baseline. Pinout yang berubah tidak mengubah wiring; UI meminta bukti profil aktual ketika kemampuan tersebut kelak ditambahkan.

### 7.3 Role dan audit

| Kemampuan | Viewer | Operator | Engineer | Admin |
| --- | --- | --- | --- | --- |
| Baca latest/alert sesuai scope | Ya | Ya | Ya | Ya |
| Ekspor data sesuai scope | Sesuai policy | Ya | Ya | Ya |
| Acknowledge alert | Tidak | Ya | Ya | Ya |
| Kendali sirine | Tidak | Ya, capability+policy | Sesuai izin eksplisit | Sesuai izin eksplisit |
| Draft kalibrasi/config | Tidak | Tidak | Ya | Ya |
| Terapkan config hardware | Tidak | Tidak | Izin khusus+ACK | Izin khusus+ACK |
| Registri/role pengguna | Tidak | Tidak | Baca sesuai scope | Ya |

Menyembunyikan tombol bukan pengamanan. Rules/API harus memeriksa hak berdasarkan sesi; PIN lokal `1234` bukan otorisasi backend. Kredensial perangkat/server tidak dimasukkan ke frontend. Audit ditulis backend: actor, action, target, request/correlation, before/after tersaring, result, waktu server. Audit command terhubung ke event perangkat; log tidak menyimpan password/token atau payload sensitif tanpa seleksi.

## 8. Latency, reconnect, stream, dan ekspor

### 8.1 Perilaku koneksi

- Koneksi cloud online dibuktikan oleh adapter SDK; heartbeat gateway tetap indikator berbeda.
- Banner “Menghubungkan ulang” muncul ketika adapter kehilangan sesi; angka lama tetap terlihat dengan umur data dan label cache/stale.
- Retry adapter awal target 1, 2, 4, 8, 16 hingga 30 detik dengan jitter, jika SDK tidak sudah menanganinya; hindari dua retry loop yang saling berlomba.
- Latency hanya dihitung untuk hop dengan timestamp sah: server→browser atau observed→received. RTT dari ping khusus berbeda dari umur sensor. Jika clock atau observed_at belum sah, tampilkan `— ms`, bukan angka perkiraan.
- Sasaran UI: loading tertunda >400 ms menampilkan skeleton; request >10 detik menampilkan pesan keterlambatan; >30 detik menawarkan retry. Ini parameter UX, bukan hasil ukur jaringan TITEN.
- Reconnect melepaskan subscription lama, memulihkan snapshot/cursor, dedupe event, lalu menghitung freshness kembali. Status stabil tidak menghasilkan toast berulang.
- Halaman background mengurangi render chart; jangan mematikan penerimaan alert yang masih dibutuhkan. Logout melepas listener dan membersihkan cache sesuai scope.

### 8.2 Stream event, filter, dan performa

Filter level: DEBUG, INFO, WARN, ERROR; toggle multi-select tanpa menyembunyikan ERROR secara default. Filter tambahan: node, gateway, transport, kategori, range waktu, correlation ID. `MQTT`/`WebSocket` hanya menjadi transport aktif setelah adapter backend tersedia; sementara route bernama **Event & log**, bukan “MQTT live”.

Autoscroll hanya saat pengguna di bawah. Saat membaca baris lama, buffer event baru dan tampilkan tombol “N event baru”; jumlah harus aktual. Pause menghentikan autoscroll/tampilan, bukan mengklaim sensor berhenti. Batasi buffer awal 1.000 baris, halaman history 100 record; nilai ini target teknis configurable. Virtualisasi diterapkan saat data cukup besar dan harus mempertahankan akses keyboard/focus.

Sort yang digunakan: `received_at` lalu key stabil; event tanpa waktu sah masuk kelompok “Waktu belum tersedia”, bukan tanggal 1970 atau “baru saja”. Filter no-result menjelaskan filter aktif dan menawarkan reset. Event invalid/CRC failure dapat tampil sebagai diagnostic bila uploader mengirimnya, tetapi tidak memperbarui nilai sensor terakhir.

### 8.3 Analitik dan export

Rentang tanggal memakai zona pilihan pengguna pada input, dikonversi ke UTC start-inclusive/end-exclusive sebelum query. Grafik default memakai satu metrik/unit per panel; perbandingan beberapa node memakai unit sama dan legenda yang dapat diakses. Downsampling untuk render harus diberi label agregasi, menyimpan min/max bila relevan; export raw tidak diam-diam memakai titik grafik teragregasi.

CSV memakai UTF-8, header/unit jelas, quoted fields, null kosong disertai kolom quality; string yang dapat dianggap formula spreadsheet di-escape. JSON membawa `schema_version`, `exported_at`, `range_utc`, `source`, `filters`, `snapshot_cutoff`, provenance, dan record asli. Ekspor belum dapat ditawarkan dari data grafik mock di LIVE. Nama berkas menyertakan scope, UTC range, dan mode; DEMO memakai awalan DEMO.

Ekspor lintas halaman mempertahankan cutoff snapshot agar data yang datang selama proses tidak menduplikasi/menyisipkan record. Batalkan unduhan dengan kontrol yang jelas; error parsial tidak menghasilkan berkas berlabel lengkap. Target browser export maksimum 10.000 record per job; volume lebih besar kelak memakai job backend dengan audit dan tautan kedaluwarsa. Ini batas produk awal yang perlu benchmark, bukan limit bawaan Firebase.

## 9. Responsif, keyboard, dan aksesibilitas

| Lebar CSS | Shell dan observabilitas | Detail dan aksi |
| --- | --- | --- |
| `<640 px` | Sidebar offcanvas, padding 16 px, satu kolom; daftar compact default; topologi collapsed dengan alternatif daftar | Drawer menjadi halaman/sheet penuh; kontrol berizin tetap tersedia dengan target 48 px, konfirmasi, serta capability yang sama |
| `640–1024 px` inklusif | Sidebar 64 px, padding 16–24 px, grid 2 kolom bila min card 280 px terpenuhi; topologi dan alert bertumpuk | Detail sheet maksimal 80% lebar atau halaman penuh; toolbar wrap, tanpa aksi terpotong |
| `>1024 px` | Sidebar 232/64 px, kanvas 12 kolom, tabel dan topologi bersamaan sesuai ruang | Drawer 480 px/maksimum 45%; audit dan inspector berdampingan jika cukup ruang |

Web mobile adalah compact view operasional; bukan blanket read-only. Aksi berbahaya memerlukan target sentuh cukup, konteks, autentikasi, dan bukti hasil yang sama. Flutter mengutamakan tindakan lapangan/tactile, sedangkan web mengutamakan perbandingan banyak perangkat serta audit. Aturan lengkap ada di matriks responsif; tepat 640 dan 1024 tetap kategori tablet.

Skip-link ke main; landmark nav/main/aside; heading berurutan; tabel mempunyai caption/header; tombol ikon mempunyai accessible name. Focus ring tidak hilang pada tema terang/gelap. Shortcut tidak aktif di input; command palette mencari route/identitas dan tidak mengeksekusi hardware. Escape menutup overlay yang aman; transaksi menampilkan keputusan batalkan draft dengan jelas.

Chart menyediakan tabel data atau ringkasan tekstual yang dapat diakses, pola/label selain warna, dan gap null. Gunakan announcer `aria-live=polite` untuk koneksi/hasil command penting, bukan setiap sampel. Error kritis dapat diumumkan satu kali sesuai severity. Hormati prefers-reduced-motion; fokus kembali ke pemicu ketika drawer ditutup. Kontras mengikuti pengujian design system, termasuk badge, metadata, placeholder dan warna plot; library saja tidak menjamin kepatuhan.

## 10. Mapping library, implementasi, dan dependensi

| Kebutuhan | Pilihan target | Catatan implementasi |
| --- | --- | --- |
| Shell/sidebar | shadcn/ui Sidebar varian Radix + Sheet | Pilih branch Radix eksplisit; open state controlled dan breakpoint disesuaikan spesifikasi |
| Tabel node/audit | shadcn/ui Table + TanStack Table bila perlu | Query/filter server dan rendering table dipisahkan; pagination bukan full-root fetch |
| Drawer/detail | Sheet, Tabs, ScrollArea, Separator | Akses focus/label diuji setelah komposisi, bukan diasumsikan |
| Form/filter/config | Input, Label, Select/Combobox, Popover, Calendar, Alert | Validasi schema domain dan server; desired/reported tak bercampur |
| Konfirmasi command | AlertDialog, Button, Badge | Transisi command dari backend; durasi/expiry wajib terlihat |
| Grafik/sparkline | Tremor source-owned LineChart/SparkChart | Sesuaikan token dan icon; null gaps, tabel alternatif; bukan KPI komponen otomatis |
| Ikon | Lucide React | Import ikon yang digunakan; stroke konsisten; accessible name pada tombol |
| Koneksi realtime | Firebase Web SDK RTDB | Adapter modular, unsubscribe, rules/index, validasi typed DTO |
| Topologi | SVG custom + daftar ekuivalen | Jangan menambah library diagram besar sebelum kebutuhan scale terbukti |
| State/data validation | Store domain + validator TypeScript | Library dipilih saat scaffold; null/quality/state wajib diuji |

shadcn menyediakan komposisi sidebar dan pola data table; contoh dokumentasi perlu disesuaikan, terutama breakpoint dan domain state. Branch Radix dipilih agar API tidak tercampur dengan branch Base UI/React Aria. [shadcn Sidebar Radix](https://ui.shadcn.com/docs/components/radix/sidebar), [shadcn Data Table Radix](https://ui.shadcn.com/docs/components/radix/data-table).

Tremor dokumentasi source-owned mengimpor komponen lokal dan memakai Recharts untuk LineChart. Pilih jalur ini sebagai target; jangan mencampur petunjuk source-owned dengan paket NPM legacy tanpa keputusan dependency. Ikon bawaan contoh chart boleh diganti Lucide agar sistem ikon tunggal. [Tremor LineChart](https://www.tremor.so/docs/visualizations/line-chart), [Tremor SparkChart](https://www.tremor.so/docs/visualizations/spark-chart).

Lucide menyediakan integrasi React; kunci versi package pada implementasi, gunakan import ikon terpilih dan audit hasil bundling. Tidak ada instalasi package yang dilakukan oleh penulisan spesifikasi ini. [Lucide React getting started](https://lucide.dev/guide/react/getting-started).

Dependensi sebelum LIVE web: uploader gateway; schema/version registry; validitas sensor; auth/rules; history/index/retensi; server timestamp; event stream; command backend dan downlink bila dijanjikan; alert engine. Konfigurasi cloud aktual belum diverifikasi. Jangan menampilkan capability enabled hanya berdasarkan rencana dokumen.

## 11. Kriteria penerimaan dan urutan implementasi

### 11.1 Skenario wajib

| ID | Skenario | Lulus jika |
| --- | --- | --- |
| W-01 | RTDB belum dikonfigurasi atau permission denied | Error eksplisit, tanpa mock otomatis, status bahaya unknown |
| W-02 | Registry query sukses kosong | Empty 0 terdaftar, instruksi setup; tidak memunculkan empat node contoh |
| W-03 | Node 1 menerima paket sensor fisik | Nilai/unit/correlation cocok capture, received_at server sah, provenance LIVE |
| W-04 | Field hilang/null dan nilai 0 valid | Null tampil `—`; nol valid tetap 0; baterai tidak default 100 dan RSSI tidak default −75 |
| W-05 | Level 0 dengan data stale/missing | Label last-known jelas; tidak AMAN hijau terkini; koneksi cloud tetap independen |
| W-06 | R/J tidak ada, clock invalid, atau planned sleep | Freshness unknown atau mengikuti jadwal sah; tidak hardcode 8 jam/menyebut offline tanpa bukti |
| W-07 | Browser offline lalu reconnect | Cache bertanggal; listener tidak dobel; command tidak auto-replay; mode DEMO tidak otomatis aktif |
| W-08 | Command ditulis lalu ACK transport tanpa eksekusi | UI accepted/delivery saja; tidak sukses/ON; expiry dan outcome ambigu ditampilkan |
| W-09 | Backend/firmware mendukung command end-to-end | Target/durasi/expiry tervalidasi, request tunggal, hasil perangkat+audit dapat ditelusuri |
| W-10 | Remote pin/config belum didukung | Read inspector tersedia; kirim disabled dengan alasan; perubahan lokal tidak disebut applied |
| W-11 | History kosong/error/bercelah | Empty/error berbeda, gap null tidak dihubungkan, tanpa chart fixture dalam LIVE |
| W-12 | Dua record waktu sama dan duplikasi reconnect | Pagination tak hilang/duplikat menurut key stabil; keterbatasan firmware dedupe terdokumentasi |
| W-13 | Export multi-page dan data datang saat export | Scope/range/cutoff/source benar, raw vs agregasi eksplisit, fixture berlabel DEMO |
| W-14 | Unauthorized write/direct route request | Ditolak backend; audit relevan; tombol tersembunyi bukan satu-satunya kontrol |
| W-15 | Lebar 639, 640, 1024, 1025 px; zoom 200%; keyboard | Tidak ada kontrol terpotong, focus terlihat, urutan baca/overlay benar, target hardware 48 px |
| W-16 | DEMO tanpa jaringan | Badge DEMO tetap jelas, cloud offline terpisah, command simulator tidak menyentuh live |
| W-17 | MQTT/WebSocket tidak tersedia | Capability false, label backend belum mendukung; tidak ada event koneksi rekaan |
| W-18 | Sensor DHT gagal pada firmware lama | Quality belum terverifikasi; angka fallback tidak dipromosikan sebagai sehat/aman |

Uji UI menggunakan fixture deterministik berlabel synthetic hanya untuk kasus null/state/error, bukan bukti perangkat. Uji integrasi menggunakan emulator/backend test serta rules. Penerimaan LIVE dan command wajib menyertakan capture/log perangkat, versi firmware/app, timestamp, langkah, serta hasil nyata. Angka latency/packet loss/power tidak dipublikasikan sebagai hasil sebelum diukur.

### 11.2 MVP lomba dan fitur lanjutan

| Tahap | Ruang lingkup | Gerbang selesai |
| --- | --- | --- |
| MVP-A: fondasi jujur | Token, shell responsif, mode, registry, adapter nullable, empty/error | Null/source/freshness/auth tidak menghasilkan status palsu |
| MVP-B: observabilitas asli | Latest node 1, gateway nyata, daftar/topologi, history, filter, export, event RTDB | Capture fisik cocok dengan UI dan export; reconnect lulus |
| MVP-C: operasi bila didukung | Alert acknowledgment, command sirine terbatas, hasil eksekusi, audit | Backend+firmware ACK/expiry/role telah diuji; jika belum, UI capability disabled |
| Peningkatan berikutnya | Remote kalibrasi/profil pin/config berversi, multi-node nyata, event MQTT/WebSocket, export job besar | Memerlukan kontrak/backend/firmware baru dan test capability |
| Ditunda | Perancangan rangkaian daya dan perhitungan energi | Di luar pekerjaan UI ini sesuai arahan pengguna |

Urutan kerja: selesaikan kontrak dan uploader → state domain + autentikasi → shell dan daftar → detail/history → event/export → alert/audit → command saat end-to-end siap → QA responsif/aksesibilitas dan latihan demo. Dokumen ini tidak menjadikan fitur future syarat untuk mulai membangun MVP observabilitas.
