# TITEN — Spesifikasi aplikasi Flutter

Versi dokumen: 1.0 · Acuan repository: 7 Oktober 2026 · Target utama: Android untuk demo lomba.
Status: spesifikasi implementasi; fitur target di bawah belum otomatis tersedia pada firmware, backend, atau APK.
Dokumen terkait: [Design system](01_DESIGN_SYSTEM.md), [Web](02_WEB_SPEC.md), [Responsif](04_RESPONSIVE_MATRIX.md), [Audit proyek](../docs/AUDIT_PINOUT_DAN_RENCANA_DEMO.md).
Lingkup power hardware ditunda. Aplikasi hanya menampilkan baterai yang benar-benar tersedia, beserta kualitasnya; dokumen ini tidak menetapkan regulator, charger, solar, atau rangkaian daya.

## 1. Tujuan, pengguna, dan batas produk

Teknisi lapangan harus dapat menjawab: perangkat mana yang mengirim, apakah datanya masih berlaku, sensor mana bermasalah, apakah ada peringatan, dan apakah tindakan hardware benar-benar dijalankan.
Operator mobile memerlukan pemeriksaan singkat, rincian node, penerimaan alert, dan kendali sirine yang dapat diaudit.
Enum role server stabil: `viewer` (Viewer/Pengamat), `operator` (Operator), `engineer` (Engineer/Teknisi), `admin` (Admin). Viewer membaca data dan riwayat tanpa kontrol hardware. Teknisi memperoleh provisioning/diagnostik sesuai penugasan; hak teknisi tidak otomatis memberikan hak aktuasi. Operator memperoleh aktuasi pada node yang ditugaskan; admin mengatur registrasi dan izin.
Satu node fisik cukup untuk demo alur lengkap. Jumlah perangkat harus berasal dari registry; jangan mengklaim konsensus beberapa node dari satu perangkat.
Keberhasilan minimum: kejadian sensor fisik → LoRa → gateway → Firebase → detail node/history → alert/push; perintah → perangkat → hasil yang terkonfirmasi.
App tidak menggantikan alarm lokal. Pengiriman push dan internet tidak menjamin keselamatan atau latensi tertentu; copy produk menyebut data/prototipe sesuai bukti uji.

| Prioritas | Lingkup | Gerbang tersedia |
| --- | --- | --- |
| P0 | Data asli, null/error, waktu, freshness, Home, daftar/detail, history | Kontrak v2, registry dan uploader tervalidasi |
| P0 | Alert asli dan push yang membuka detail | Backend terpercaya, FCM, otorisasi dan pengujian HP |
| P0 | Sirine ON/OFF dengan hasil perangkat | Command service, jalur downlink/RX node, ACK eksekusi |
| P1 | Cache SQLite, reconnect, diagnostik dan aksesibilitas | Migrasi cache, auth/rules dan uji gangguan |
| P1 | Registrasi melalui wizard BLE/SoftAP | Firmware provisioning aman dan adapter native telah diuji |
| P2 | iOS, ekspor lapangan, peta offline berlisensi | Platform, kebijakan penyimpanan dan paket tambahan divalidasi |

## 2. Bukti implementasi saat ini dan keputusan library

Acuan versi berikut berasal dari batas dependency di `titen_app/pubspec.yaml`, bukan klaim versi resolved terakhir. Cocokkan `pubspec.lock`, SDK, dan changelog sebelum implementasi; jangan melakukan upgrade mayor hanya untuk menyamakan dokumentasi terbaru.

| Area | Sudah dideklarasikan | Keputusan implementasi |
| --- | --- | --- |
| State | `flutter_riverpod ^2.5.1` | Pertahankan provider 2.x; AsyncValue untuk load/error, state domain eksplisit untuk freshness/command |
| Routing | `go_router ^14.2.0` | Adaptasi StatefulShellRoute yang ada; redirect auth dan route alert tervalidasi |
| Transport | `firebase_core ^4.15.0`, `firebase_database ^12.6.0` | RTDB menjadi remote source; MQTT belum menjadi transport aplikasi |
| Push | `firebase_messaging ^16.7.0`, `flutter_local_notifications ^22.3.1` | Lengkapi lifecycle, token, dedupe dan navigasi; izin diberikan sesuai pilihan pengguna |
| Grafik | `fl_chart ^0.68.0` | Sparkline sederhana dengan titik nyata; segmentasi gap/null di adapter data |
| Peta | `flutter_map ^7.0.2`, `latlong2 ^0.9.1`, tile provider | Peta opsional dari koordinat registry; jangan menghasilkan koordinat |
| Font | `google_fonts ^6.2.1`, `intl ^0.19.0` | Bundle lokal Inter/JetBrains Mono; format lokal Indonesia dan label zona waktu |
| UI | Flutter Material, `cupertino_icons ^1.0.8` | Material shell bertoken TITEN; jangan menambah dua sistem theme global |
| Belum terpasang | `shadcn_ui`, `flutter_lucide`, `sqflite`, `path`, library BLE/auth | Usulan dependency baru, bukan fasilitas yang telah tersedia |

Pilihan utama UI: `MaterialApp.router`, `ThemeExtension<TitenTokens>`, `CustomScrollView`/sliver, serta komponen kecil yang memakai token dari dokumen 01.
`shadcn_ui` merupakan opsi adapter terisolasi untuk input/badge/sheet jika dibutuhkan; bukan kewajiban mengganti shell native. Paket tersebut merupakan port Flutter komunitas, bukan Radix DOM di Flutter. [Paket resmi pemelihara](https://pub.dev/packages/shadcn_ui).
Ikon awal memakai Material outlined yang konsisten. Jika Lucide ditambahkan, verifikasi nama paket, lisensi, versi, dan ukuran bundle; jangan mengimpor `flutter_lucide` seolah sudah terpasang.
SQLite dipilih lewat usulan `sqflite` + `path` untuk Android. Flutter Web perlu adapter penyimpanan tersendiri; paket tersebut tidak otomatis menyediakan backend browser. [Panduan Flutter SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite).
Tambahkan auth SDK yang kompatibel serta client HTTPS/callable backend saat kontrak server ditetapkan. PIN lokal `1234` tidak menjadi otorisasi.

## 3. Model data dan status yang wajib dipisahkan

### 3.1 Empat dimensi status

| Dimensi | Nilai | Makna dan presentasi |
| --- | --- | --- |
| Sumber data | `live`, `demo` | LIVE menggunakan pipeline perangkat; DEMO memakai fixture yang selalu diberi label sintetis |
| Koneksi app | `online`, `reconnecting`, `offline`, `unknown` | Hubungan client ke layanan; tidak membuktikan gateway/node hidup |
| Freshness node | `fresh`, `stale`, `missing`, `unknown` | Usia paket berdasarkan jadwal report registry; berbeda dari status jaringan |
| Bahaya | `hazard_level` 0/1/2/3 atau null | Aman/Waspada/Siaga/Awas berdasarkan evaluasi yang valid; null berarti belum dapat dinilai |

Chip mode global menampilkan LIVE, DEMO, atau OFFLINE. OFFLINE merupakan presentasi koneksi; metadata tetap mencatat sumber cache sebelumnya, misalnya `OFFLINE · cache LIVE`.
Status gateway (`online/degraded/offline/unknown/maintenance`) ditentukan heartbeat/backend; validitas sensor individual (`valid/invalid/unsupported/unavailable`) dan status kalibrasinya tetap terpisah.
Tidak ada fallback mock pada LIVE, termasuk pada grafik. `hazard_level` null atau di luar kontrak tidak boleh menjadi 0. Adapter memetakan field firmware/legacy `status_level` menjadi domain `hazard_level` secara eksplisit.
Ketika data stale/offline, tampilkan `Terakhir: Aman` dengan waktu dan gaya netral/amber; jangan menunjukkan banner hijau `Semua aman`.
Ringkasan bahaya menggunakan maksimum level dari evaluasi fresh dan valid. Jika ada unknown, beri keterangan cakupan `Sebagian node belum dapat dinilai`.
Unresolved alert tidak otomatis level 3; gunakan `hazard_level` alert, sumber dan waktu kejadiannya.

### 3.2 Freshness dan waktu

Gunakan rumus bersama dokumen 04: `R = registry.expected_report_interval_ms`, `J = registry.delivery_grace_ms`, `age = trusted_now - received_at`.
`fresh`: age ≤ R+J; `stale`: R+J < age ≤ 3R+J; `missing`: age > 3R+J. R harus positif, J harus tersedia dan tidak negatif.
Nilai R adalah jadwal paket yang diharapkan, bukan interval sampling sensor. Firmware tidur terencana/maintenance memerlukan jadwal tersendiri dan alasan yang terlihat.
`missing` menjadi node offline hanya bila kontrak report yang valid atau fakta eksplisit server mendukungnya; jika R/time tidak tersedia, gunakan unknown.
Gunakan offset waktu server yang terukur, monotonic elapsed saat foreground, lalu validasi ulang saat resume; jam HP mundur/maju tidak boleh mengubah data lama menjadi fresh.
Setelah jam terpercaya, gunakan `age=max(0, trusted_now-received_at)` untuk toleransi rounding kecil. Clock skew melampaui toleransi konfigurasi menghasilkan `Waktu tidak valid`/unknown; clamp tidak boleh menutupi clock yang belum terpercaya.
`observed_at` adalah waktu observasi UTC ISO 8601 dan nullable; `received_at` adalah waktu penerimaan UTC ISO 8601 dari server terpercaya.
Legacy `timestamp_rtc` pada firmware sekarang diisi `millis()/1000`; perlakukan sebagai uptime, bukan tanggal Unix.
ServerValue.timestamp yang masih berbentuk epoch milidetik hanya dinormalisasi oleh adapter; jangan mencampur detik, milidetik dan ISO secara implisit.
UI memakai WIB untuk pengguna Asia/Jakarta dengan format `7 Okt 2026, 21:04:05 WIB`; tap metadata membuka timestamp UTC mentah. Angka waktu ini hanya contoh format sintetis.

### 3.3 Kontrak target v2

`node_id` tetap numerik; firmware sekarang menetapkan `NODE_ID 1`. `node_key = node_01` merupakan key registry untuk node tersebut, bukan identifier yang boleh ditebak dari sembarang string.
`gateway_id` merupakan string yang diterbitkan registry; belum ada ID gateway terverifikasi sehingga tidak diisi otomatis sebagai `gateway_01`.
Target path: `registry/nodes/{node_key}`, `registry/gateways/{gateway_id}`, `gateway_status/{gateway_id}`, `nodes/{node_key}/latest`, `history/{node_key}/{event_id}`, `alerts/{alert_id}`, `commands/{command_id}`, `events/{event_id}`, `audit/{audit_id}`.
Path ini merupakan desain target, belum deployment. Data flat `nodes/node_01` saat ini masuk adapter v1 eksplisit, bukan dibaca bergantian dengan v2 tanpa penanda.
Unique telemetry key: `(gateway_id, node_id, session_id, sequence)`; reboot menghasilkan session baru. Sequence lama tidak menimpa latest lebih baru; history tetap dedupe.
Firmware paket 16 byte saat ini belum membawa seluruh metadata v2. Gateway/backend harus menyediakan metadata atau mengubah versi paket; app tidak mengarang sequence maupun session.

```json
{
  "schema_version": 2,
  "node_id": 1,
  "node_key": "node_01",
  "gateway_id": null,
  "session_id": null,
  "sequence": null,
  "observed_at": null,
  "received_at": null,
  "battery_pct": null,
  "tilt_deg": null,
  "soil_moisture_pct": null,
  "air_temp_c": null,
  "air_humidity_pct": null,
  "flame_detected": null,
  "rssi_dbm": null,
  "snr_db": null,
  "hazard_type": null,
  "hazard_level": null,
  "quality": { "validity": "unavailable", "reason": "no_packet" },
  "source": "live"
}
```

Contoh tersebut mencerminkan pengetahuan tersedia: ID node 1 berasal dari konfigurasi firmware; seluruh pembacaan, identitas gateway dan waktu belum dibuktikan. Ini state draft/unknown, bukan payload lengkap yang boleh diterima ingestion v2.
Ingestion v2 mewajibkan gateway_id, session_id, sequence, received_at valid; draft gagal validasi ditampilkan sebagai masalah setup, tidak disimpan seolah event sensor sah.
Setiap measurement memakai nullable value, unit baku dan quality per field (`valid/invalid/unsupported/unavailable`), dengan reason seperti `not_calibrated` atau `sensor_error`. `0` berbeda dari tidak ada; boolean false berbeda dari unknown.
Field persen harus 0–100; float nonfinite, tipe salah, status di luar 0–3, koordinat di luar rentang ditolak per field dan dicatat tanpa membuang field lain yang valid.
`soil_moisture_pct` berlabel `Kelembapan tanah relatif (%)`; helper menjelaskan indeks hasil kalibrasi, bukan kadar air volumetrik tanpa kalibrasi ilmiah.
Lokasi, nama, tipe perangkat, band radio, firmware version dan capabilities berasal dari registry. Nama fallback hanya `Node 01`, bukan lokasi rekaan.
Registry menyertakan `capabilities` untuk `relay_control`, `command_ack`, `provisioning_ble`, `provisioning_softap`, `calibration`, dan `flame_measurement`; default semuanya false sampai terbukti.
Field flame belum dikirim pada paket sekarang; tampilkan `Tidak tersedia pada payload ini`, bukan `Tidak ada api`.
Kontrak alert: alert_id, node_ids numerik, hazard_type/level nullable, lifecycle open/acknowledged/resolved, occurred_at nullable, received_at, evidence_event_ids, revision, actor/time acknowledgment, dan source.
Alert_id tidak diganti menjadi konstanta `alert_default`; identitas yang hilang menghasilkan record invalid agar dedupe tidak menggabungkan kejadian berbeda.

## 4. Arsitektur halaman dan navigasi

### 4.1 Shell dan route

Mobile memiliki empat destinasi bawah: **Ringkasan**, **Perangkat**, **Peringatan**, **Alat**. Pengaturan ada di Alat; peta dan analitik mendalam menjadi route turunan Perangkat.
Pertahankan state scroll/filter tiap branch melalui StatefulShellRoute. Pemilihan tab aktif tidak mereset layar tanpa tindakan eksplisit.
Gunakan SafeArea pada area konten/kontrol, insets keyboard pada sheet, dan padding bawah sesuai navigation bar. Jangan menumpuk dua SafeArea sehingga muncul ruang kosong.
Shell <640dp memakai NavigationBar; 640–1024dp memakai NavigationRail dan master/detail bila ruang cukup; >1024dp memakai navigasi tetap dengan canvas lebar terbatas.
Breakpoint memakai logical pixels dari constraints Flutter; DPR tidak mengubah breakpoint. Pada font 200%, reflow menjadi satu kolom walau lebar layar tablet.

| Route target | Isi | Guard / fallback |
| --- | --- | --- |
| `/` | Home health | Auth scope atau cache lokal pengguna yang sama |
| `/devices` | Daftar node/gateway dan filter | Tanpa data → panduan setup; kosong server adalah list kosong sah |
| `/devices/nodes/:nodeId` | Detail telemetri dan relay | ID bukan angka/rentang salah → not found; tidak fallback ke node 1 |
| `/devices/gateways/:gatewayId` | Heartbeat, firmware, report cadence, transport | ID registry dan izin baca wajib |
| `/devices/nodes/:nodeId/history` | Tren dan tabel observasi | Interval nyata, gaps, time quality |
| `/devices/map` | Lokasi registry | Tanpa koordinat → list `Lokasi belum diisi` |
| `/alerts`, `/alerts/:alertId` | Log dan evidence alert | Auth dahulu; unauthorized tidak menampilkan isi sensitif |
| `/tools`, `/tools/provision` | Diagnostik dan wizard | Role + firmware capability + adapter tersedia |
| `/tools/settings` | Tema, haptics, notifikasi, cache | Preferensi lokal; permission OS diperiksa ulang |

Route lama `/sensors/:id`, `/emergency`, `/settings`, `/map`, `/analytics` diberi redirect yang diuji agar tautan internal/notification tidak putus.
Parsing route dan payload push menggunakan allowlist; jangan menavigasi URL mentah dari pesan remote. Back dari push membuka daftar alert/Home secara konsisten.
GoRouter mendukung deep link, redirect dan shell navigator; spesifikasi ini mengikuti versi 14.x yang dideklarasikan, bukan API mayor terbaru. [Referensi pemelihara 14.2.0](https://pub.dev/packages/go_router/versions/14.2.0).

### 4.2 Home / Ringkasan

Urutan sliver: top bar + mode → koneksi/data freshness → gateway health → ringkasan node → alert aktif → node yang perlu diperiksa → tindakan alat.
Top bar berisi nama lokasi dari registry atau `Lokasi belum diatur`, waktu sync terakhir dan tombol pengaturan tanpa avatar/nama organisasi rekaan.
Gateway health memisahkan link cloud, LoRa receiver, heartbeat, backlog upload, clock status, dan firmware; `Cloud tersambung` tidak menjadi `Semua node online`.
Ringkasan node menghitung dari registry yang boleh diakses: fresh/stale/missing/unknown, sensor error, dan node dengan alert. Jika registry belum diterima, jumlah adalah `—`, bukan 0.
Daftar prioritas mengurutkan alert kritis → sensor error → missing/stale → node fresh. Saat user menekan/scroll, tunda reorder sampai interaksi selesai agar salah tap tidak terjadi.
Baterai dan RSSI ditampilkan per node, bukan rata-rata yang menutupi perangkat bermasalah. Nilai baterai belum dikalibrasi diberi label estimasi; tanpa field → `—`.
RSSI dari gateway memakai dBm; SNR memakai dB; indikator bar hanya boleh berasal dari threshold radio yang terversi, bukan ambang WiFi yang dipakai ulang.
Pull-to-refresh meminta refresh server/registry; tidak memerintahkan sampling node. Saat offline, selesai dengan `Belum tersambung; cache terakhir dipertahankan`.
Refresh yang gagal tidak menghapus cache sah. Cache kosong menampilkan onboarding dan retry, tidak skeleton tanpa batas.

### 4.3 Daftar dan detail perangkat

Node row: nama/ID, dua badge terpisah (freshness dan bahaya), timestamp, baterai, RSSI, serta chevron detail. Target seluruh row minimal 48dp tinggi.
Filter: jenis perangkat, freshness, level bahaya dan error sensor. Search memakai nama/node_id/gateway_id; hasil kosong berbeda dari registry kosong.
Detail menampilkan header identity → freshness → sensor tiles → sparkline → relay/command log → metadata firmware/radio/lokasi.
Informasi pinout hanya metadata profil terverifikasi; tidak ada tombol mengubah GPIO produksi tanpa firmware/config service. Penundaan power tidak menghapus informasi sensor tetapi menonaktifkan kesimpulan baterai palsu.
Tap measurement membuka sheet berisi value+unit, waktu, quality, sumber, kalibrasi aktif, event ID, dan grafik field yang sama.
Rentang grafik 15 menit/1 jam/24 jam merupakan pilihan query, bukan jaminan riwayat tersedia. Rentang kosong menampilkan `Belum ada sampel pada rentang ini`.
Sparkline memakai sumbu waktu yang benar, unit tetap, tooltip dengan timestamp, garis 1.5–2dp, tanpa area gradient dan tanpa smoothing yang melampaui nilai observasi.
Gap di atas ambang report R+J dan measurement invalid memutus garis. Satu titik tampil sebagai titik, bukan kurva atau garis datar yang dibuat sendiri.
Downsampling mempertahankan min/max serta kejadian penting; detail/tabel tetap dapat mengakses sampel asli dan jumlah titik yang diringkas.
Latensi upload dan umur observasi dipisahkan. Jika observed_at unknown, beri label `Waktu observasi tidak tersedia; urut menurut penerimaan`.
Peta tidak memerlukan permission lokasi HP untuk menunjukkan koordinat node. Tombol `Lokasi saya` meminta izin hanya saat digunakan; tile gagal tidak menghalangi detail node.

## 5. Katalog komponen Flutter

Semua warna berikut merujuk token persis dokumen 01. Light/dark mengikuti sistem sebagai default, dengan pilihan manual; jangan hardcode hex di widget.

| Singkatan visual katalog | Token implementasi |
| --- | --- |
| canvas / surface / hover | `surface.canvas` / `surface.panel` / `surface.subtle` |
| sheet / border / control border | `surface.raised` / `border.subtle` / `border.control` |
| text / muted / focus | `text.primary` / `text.metadata` / `border.focus` |
| emerald / amber / rose / sky / unknown | `semantic.normal` / `semantic.warning` / `semantic.critical` / `semantic.syncing` / `semantic.unknown`, masing-masing `.fg/.bg/.border` |
| CTA utama netral | `action.primary.bg` / `action.primary.fg` |

UI Inter 14–16sp, judul 18–24sp, metadata mobile minimal 13sp, angka JetBrains Mono 18–24sp. Body/control comfortable memakai varian `type.bodyComfortable`/`type.controlComfortable` 16/24 bila ergonomi membutuhkan. Ukuran 11–12 hanya micro pendamping pada canvas desktop dengan label utama yang tetap terbaca; jangan dipakai untuk pesan, unit atau metadata utama mobile. Spacing 4/8dp, padding 12/16dp, radius 6/8/10dp, border 1dp dan elevasi minimal.
`F` = focus keyboard/screen-reader yang terlihat + label semantics; `A` = pressed/selected; hover hanya pointer dengan surface satu tingkat, tanpa glow. Fokus memakai outline 2dp dan tidak mengandalkan warna saja.
Tidak ada measurement aktual yang diverifikasi pada audit. Kolom contoh di bawah memakai node_id 1 yang diketahui, nilai unknown yang jujur, atau placeholder kontrak; fixture angka pengujian wajib berlabel `SINTETIS`.

| ID / Nama / fungsi | Visual | Default · focus/active | Disabled · error/alert · loading | Contoh sesuai bukti |
| --- | --- | --- | --- | --- |
| M01 AppShell — navigasi utama | surface, border atas 1dp, Inter 13/14, area ≥48dp | Ringkasan aktif; F outline; A ikon+label terpilih | Disabled route tanpa role disertai alasan; error route recovery; loading konten tidak menghilangkan nav | `Ringkasan · Perangkat · Peringatan · Alat` |
| M02 ModeChip — provenance data | radius6, mono13, LIVE/DEMO keluarga unknown netral; OFFLINE mengikuti transport | Mode selalu terlihat; F membuka penjelasan; A tidak mengganti source langsung | Disabled pergantian saat command/provisioning berjalan; error mode tidak diketahui → UNKNOWN; loading `Memeriksa sumber` | `LIVE · Belum ada paket` |
| M03 SyncBanner — koneksi app | full-width border, sky/amber, Inter13 | `Tersambung ke layanan`; F retry; A refresh | Disabled retry saat aktif; error auth/timeout dengan aksi; loading indikator kecil dan cache tetap | `OFFLINE · cache LIVE · Waktu belum diketahui` |
| M04 GatewayHealth — kesehatan gateway | surface radius8, grid key/value, mono14 | Ringkasan dari heartbeat; F buka detail; A surface pressed | Disabled control bila read-only; error unknown/degraded berlabel; loading skeleton key/value | `Gateway belum terdaftar · LoRa belum terverifikasi` |
| M05 FleetSummary — cakupan node | border radius8, 2 kolom adaptif, Inter13/mono20 | Hitungan registry; F tile filter; A filter terpilih | Disabled bila registry unknown; error izin; loading `—` tanpa jumlah palsu | `Registry belum diterima · Node fisik target: 1` |
| M06 NodeRow — pemeriksaan cepat | radius6, divider, mono ID, Inter14, min tinggi72 | Identity+freshness+hazard; F row; A buka detail | Disabled aksi tetapi baca tetap; error sensor/stale badge; loading skeleton bukan node dummy | `Node 01 · Data belum tersedia · Baterai — · RSSI —` |
| M07 StatusBadge — level/domain | radius6, icon+teks, Inter13, semantic border | Aman hanya valid fresh; F metadata jika interaktif; A sheet status | Disabled noninteractive tetap terbaca; error `Belum dinilai`; loading `Memeriksa` | `Bahaya: belum dinilai · Koneksi: unknown` |
| M08 FilterSearch — penyaringan | input radius6, Inter14, border, target48 | Query kosong; F label/outline; A chip terpilih | Disabled saat scope belum diketahui; error query invalid; loading hasil mempertahankan input | `Cari Node 01` |
| M09 NodeIdentity — metadata detail | header surface radius8, Inter18, mono13 | Node+registry profile; F metadata link; A salin ID | Disabled edit role viewer; error metadata tidak lengkap; loading placeholder ID tetap | `node_id: 1 · Lokasi belum diisi` |
| M10 TelemetryTile — measurement | radius8, Inter14 label/mono24 angka, unit14 | Value null `—`; F buka evidence; A sheet | Disabled field unsupported; error `Sensor gagal`; loading skeleton hanya saat belum ada cache | `Suhu — °C · Belum ada pengukuran` |
| M11 Sparkline — tren asli | radius8, netral/semantic line, mono13 axis | Plot sampel valid; F tabel alternatif; A tooltip tidak membuat sampel | Disabled zoom tanpa data; error query inline; loading cache chart + spinner | `Node 01 · Belum ada riwayat` |
| M12 RelayToggle — mengusulkan ON/OFF | dua pilihan radius6, text14, state aktual mono14 | Terpilih dari state terkonfirmasi; F ON/OFF; A buka confirm, bukan ubah hardware visual | Disabled offline/stale/no role/no capability; error unknown/failure eksplisit; loading requested terpisah | `Keadaan relay: belum diketahui · Kontrol belum didukung` |
| M13 ActionConfirmSheet — konfirmasi aktuasi | sheet radius10, heading18, target/durasi/expiry mono13 | Target+aksi+risiko; F awal judul lalu Batal; A Kirim | Disabled submit invalid; error server/izin dengan data utuh; loading submit tunggal, cegah double tap | `Target Node 01 · Aktifkan sirine · Durasi belum dipilih` |
| M14 CommandProgress — hasil perintah | radius8, timeline vertikal, mono ID, sky waiting/rose fail | Status domain; F buka audit; A manual refresh | Disabled retry selama nonterminal; error gagal/expired; loading bukan sukses | `Belum ada perintah · ACK perangkat belum tersedia` |
| M15 AlertRow — kejadian | divider, semantic left rule2dp, Inter14, mono13 waktu | Lifecycle+level+node; F row; A detail | Disabled acknowledge tanpa role; error evidence tidak lengkap; loading skeleton | `Node 01 · Belum ada alert terverifikasi` |
| M16 AlertEvidence — bukti/pengakuan | surface radius8, field list, no decorative map | Evidence event asli; F link node/ack; A konfirmasi ack | Disabled ack offline/resolved; error conflict revision; loading cache + asalnya | `Waktu observasi — · Evidence belum tersedia` |
| M17 ProvisioningStepper — tahap setup | stepper border, radius8, Inter14, progress teks | Satu tahap aktif; F heading/input; A lanjut/back | Disabled firmware unsupported; error stage spesifik; loading bounded+Batalkan | `BLE provisioning belum tersedia pada firmware` |
| M18 DiscoveryRow — pilih gateway dekat | surface radius6, ID mono13, label Inter14 | Identitas hasil scan; F row; A secure handshake | Disabled perangkat claimed/unsupported; error proof tidak cocok; loading status scan | `Belum ada gateway ditemukan` |
| M19 WiFiCredentialForm — kirim jaringan aman | input radius6, password tersembunyi, text14 | SSID manual/scan aman; F label; A tampil password sementara | Disabled tanpa sesi terautentikasi; error password/AP; loading koneksi dengan batas waktu | `SSID belum diisi · Kata sandi tidak disimpan` |
| M20 PermissionGate — izin OS | surface radius8, ikon+tujuan konkret, Inter14 | Jelaskan sebelum request; F CTA; A buka prompt/settings | Disabled fitur ditolak; error permanently denied dengan Settings; loading pengecekan singkat | `Izin Bluetooth dibutuhkan untuk menemukan gateway` |
| M21 FieldDiagnostics — pemeriksaan setup | daftar cek radius8, mono key/value, Inter13 | Pemeriksaan baca saja; F rincian; A retry langkah | Disabled test unsupported; error instruksi pemulihan; loading tiap cek independen | `RTDB belum terverifikasi · Firmware provisioning belum ada` |
| M22 CacheStatus — asal dan usia cache | footer border, mono13, netral/amber | Label source+last sync; F kebijakan cache; A refresh | Disabled clear saat transaksi; error storage full; loading init/migrasi | `Cache kosong · Belum pernah sinkron` |
| M23 EmptyErrorState — recovery | icon20, judul16, body14, tombol radius6 | Kosong menjelaskan next step; F retry; A retry | Disabled aksi tanpa permission; error pesan spesifik+request ID; loading bounded | `Belum ada data Node 01. Periksa uploader gateway.` |
| M24 Preferences — tema/haptic/push | grouped list radius8, Inter14, native targets48 | System theme/haptic pilihan tersimpan; F control; A update preference | Disabled oleh OS/capability dengan alasan; error simpan gagal; loading state lama dipertahankan | `Tema: Sistem · Haptic: sesuai preferensi` |

Komponen disabled tetap memiliki teks alasan yang bisa dibaca assistive technology. Tooltip tidak menjadi satu-satunya tempat menjelaskan penolakan.
Skeleton hanya untuk layout yang sedang dimuat; tidak memperlihatkan angka, level Aman, daftar node, atau sparkline fiktif.
Alert critical tampil rose dengan kata `Awas` dan ikon; offline juga dapat rose, namun label/icon wajib membedakan keduanya.

## 6. Kendali relay/sirine yang benar-benar terkonfirmasi

Kontrol tersedia jika role, scope, source LIVE, koneksi online, node fresh, capability relay_control+command_ack, dan service command sehat. Kondisi lain menampilkan alasan serta alternatif diagnostik.
Jika aktuator tidak memiliki feedback kontak/arus, UI hanya boleh mengatakan `Output relay dikonfirmasi ON oleh firmware`; jangan mengklaim `Sirine berbunyi` dari status GPIO saja.
Domain menyimpan `reported_state`, `reported_at`, `state_quality`, `requested_state`, `command_id` terpisah. State lama/unknown tidak ditafsirkan sebagai OFF.
Tap ON/OFF membuka sheet berisi target Node 01, aksi, durasi terbatas, expiry server, keadaan terakhir, dampak, dan tombol Batal/Kirim.
Default fokus pada judul/aksi aman. Tombol submit harus menyebut tindakan `Aktifkan sirine Node 01`, bukan `OK`; ON dan OFF sama-sama membutuhkan target jelas.
Setiap permintaan memakai command_id/idempotency_key unik yang stabil selama satu submit. Double tap, timeout HTTP dan retry jaringan tidak menghasilkan aktuasi ganda.
Submit lewat endpoint backend online yang memvalidasi token, role, target, expiry, durasi, dan kebijakan. Jangan menulis hardware command lewat SDK RTDB yang dapat mengantre saat offline.
Backend mencatat `requested` setelah pengguna mengonfirmasi; `accepted` berarti server mengesahkan pekerjaan, bukan bukti gateway/node menerima; `executing` berarti perangkat mulai menjalankan; `succeeded` memerlukan hasil perangkat yang sesuai target/action. Penerimaan transport gateway dicatat terpisah.
Terminal lain: `failed`, `expired`, `cancelled`. Backend memiliki otoritas status terminal dan audit; client tidak boleh menaikkan requested menjadi succeeded.
ACK upload/database/LoRa transport bukan bukti eksekusi. `device_ack` wajib memuat command_id, target, hasil, reported_state, device/session identity dan waktu penerimaan terpercaya.
Jika radio belum mengautentikasi ACK, tandai tingkat assurance dan batasi sebagai demo; CRC saja tidak membuktikan identitas pengirim. Produk operasional memerlukan autentikasi device/ACK.
Expiry server membatasi awal eksekusi; server hanya menetapkan `expired` bila pekerjaan belum dimulai. `executing` tanpa hasil setelah SLA menampilkan `Hasil belum diketahui`, tetap direkonsiliasi, bukan otomatis expired/gagal. ACK terlambat dicatat dan diverifikasi server; command yang terminal expired tidak otomatis sukses atau dipicu ulang.
Saat jaringan putus setelah submit, tampilkan `Status perintah belum diketahui`; setelah reconnect query command_id yang sama. Jangan mengirim ulang otomatis.
Tidak ada antrean aktuasi offline, baik di SQLite, Riverpod, work manager maupun persistence RTDB. Setelah kembali online, pengguna memulai tindakan baru secara sadar.
Cancel hanya tersedia bila backend menjamin pembatalan sebelum eksekusi. Menutup sheet tidak membatalkan command yang telah dikirim; jelaskan statusnya dan pertahankan progress di detail.
Perintah OFF baru juga terkonfirmasi, bukan optimistik. Untuk risiko/keadaan tak diketahui, tampilkan panduan memeriksa perangkat fisik dan hubungi operator.
Haptic keberhasilan aktuasi hanya setelah ACK eksekusi yang valid; tap/accepted tidak memakai pola sukses. Haptic opsional mengikuti preferensi/OS; kegagalan diberi teks, bukan hanya getar.
Log menyertakan actor, target, action, alasan, requested_at, expires_at, transitions, firmware result, request ID dan hasil. Password, token dan secret tidak masuk log.

## 7. Tool lapangan dan commissioning BLE / Wi-Fi

### 7.1 Capability gate dan dependensi firmware

Saat ini gateway hanya menerima LoRa/menampilkan LCD/Serial; include WiFi tidak membuktikan uploader atau provisioning sudah ada. Tidak ada BLE adapter di pubspec.
Entry Alat tetap menampilkan `Tambah gateway` sebagai kemampuan yang direncanakan; sebelum fitur siap, tombol detail menjelaskan kebutuhan firmware, sedangkan CTA scan/kirim kredensial disabled.
Wizard aktif hanya setelah firmware build yang diuji melaporkan transport dan versi protokol; remote flag UI saja tidak mengesahkan kemampuan perangkat.
Keputusan target: BLE untuk discovery dan pengiriman kredensial WiFi 2,4GHz pada ESP32/ESP32-S3; SoftAP sebagai fallback hanya jika firmware mengumumkannya.
Gunakan adapter platform channel ke SDK provisioning Espressif yang kompatibel, bukan protokol GATT/crypto rekaan. Uji Android lebih dahulu; iOS terpisah.
Pilih Security 2 SRP6a + AES-GCM dengan username/password perangkat unik sebagai bukti kepemilikan; QR fisik membawa identifier dan kredensial onboarding, bukan token admin Firebase. Ini pilihan target yang harus dikunci bersama versi firmware. [Espressif Unified Provisioning](https://docs.espressif.com/projects/esp-idf/en/v5.5/esp32s3/api-reference/provisioning/provisioning.html).
Istilah `PoP` pada UI berarti bukti kepemilikan; parameter literal PoP Security 1 berbeda dari salt/verifier Security 2. Jangan mengirim PoP kosong atau turun ke Security 0 untuk mengatasi error.
Firmware membutuhkan mode provisioning dengan jendela waktu/aktivasi fisik, credential unik, endpoint capability/identity/version, scan WiFi, status connect, staged config/commit/rollback, serta factory-reset yang eksplisit.
NVS/config sebelumnya dipertahankan sampai koneksi baru teruji dan commit. Secret tidak dicetak Serial; backend memberikan enrollment grant singkat dan memastikan gateway belum diklaim pihak lain.
Keberhasilan WiFi bukan registrasi cloud. Gateway harus membuktikan identitas ke backend lewat kredensial device dan cloud heartbeat; role/assignment diputuskan server.

### 7.2 Urutan wizard dan hasil tiap tahap

| Tahap | Tindakan pengguna / sistem | Syarat lanjut dan pemulihan |
| --- | --- | --- |
| 0 Persiapan | Login role commissioning, pilih lokasi nyata, baca cara masuk mode setup | Firmware dan adapter mendukung; jika belum, tampilkan checklist instal firmware |
| 1 Izin | Minta Bluetooth/scan sesuai OS; kamera hanya jika memilih scan QR | Penolakan tidak mengunci app; sediakan input manual dan Settings |
| 2 Identifikasi | Scan BLE dengan service UUID allowlist; cocokkan QR/device ID | Nama BLE saja tidak cukup; dedupe discovery memakai ID; scan berhenti saat keluar |
| 3 Bukti kepemilikan | Handshake aman memakai kredensial unik | Gagal proof → stop, batasi retry; jangan menampilkan/merekam secret |
| 4 Kapabilitas | Baca protocol/firmware/model/transport/radio | Tidak kompatibel → instruksi firmware; tidak lanjut mengirim WiFi |
| 5 Jaringan | Pilih hasil scan AP gateway atau isi SSID; masukkan password | Jelaskan WiFi 2,4GHz; network enterprise/captive portal unsupported diberi alasan |
| 6 Stage dan uji | Kirim dalam sesi aman; gateway mencoba jaringan baru | Timeout/salah password menampilkan alasan tanpa menghapus config terakhir |
| 7 Registrasi cloud | Backend claim dengan enrollment grant; cek heartbeat | Tanpa internet `WiFi terhubung, registrasi belum selesai`; tidak membuat gateway ONLINE |
| 8 Commit | Persist config/assignment setelah bukti cloud; tutup provisioning | Masuk detail gateway; node belum mengirim tetap `Menunggu paket LoRa` |
| 9 Validasi | Terima satu paket nyata Node 01 dan cocokkan registry | Jika belum ada paket, setup gateway selesai tetapi alur sensor masih belum lulus |

Nilai timeout tiap tahap merupakan konfigurasi yang terversi dan diukur pada perangkat; progress menyebut tahap, bukan persentase palsu 0–100.
Back/gesture keluar sebelum stage menghentikan scan/session dan membersihkan password RAM. Sesudah stage minta pilihan lanjut/rollback; tampilkan dampak dengan jelas.
Cancel rollback hanya dinyatakan berhasil setelah ACK rollback firmware. BLE terputus menghasilkan `Pembatalan belum dikonfirmasi`; wizard dapat memeriksa sesi saat tersambung lagi tanpa memutar ulang kredensial.
App mati saat setup: simpan hanya ID sesi/device/stage nonsensitif dan expiry, lalu lakukan status query saat dibuka; password/enrollment secret tidak masuk SQLite.
Setelah commit, batal tidak melakukan factory reset. Reset registrasi/credential adalah tindakan admin terpisah dengan bukti kepemilikan baru.
Commissioning offline lokal boleh memverifikasi koneksi bila firmware mendukung; cloud claim dan role assignment menunggu pengguna kembali online secara eksplisit.
Untuk Android 12+ gunakan BLUETOOTH_SCAN/CONNECT sesuai fungsi. Versi lama mungkin memerlukan lokasi untuk scan; minta minimal sesuai target SDK, jangan izin lokasi sepanjang waktu. [Android Bluetooth permissions](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions).
Koneksi SoftAP memakai UI jaringan OS/platform API yang sah; jangan mengklaim app dapat selalu mengganti WiFi tanpa prompt. Verifikasi izin local network/Bluetooth pada iOS sebelum dukungan dipublikasikan.

## 8. Alerts, push log dan lifecycle aplikasi

Daftar alert memisahkan Aktif, Diakui dan Selesai, dengan filter node/hazard/level/rentang waktu. Read/unread lokal berbeda dari acknowledgment operasional.
Swipe pada row hanya menandai dibaca atau membuka tindakan; swipe tidak menghapus alert server, menyelesaikan insiden, ataupun mematikan sirine.
Acknowledge menyatakan operator telah melihat; resolve memerlukan role dan evidence resolusi. Bahaya tidak otomatis hilang setelah acknowledgment.
Alert detail menampilkan level asli, sumber rule/firmware, waktu observasi/penerimaan, node terkait, evidence measurement dan quality; konsensus hanya ditulis jika backend benar-benar menghasilkan evidence multi-node.
Push bukan sumber kebenaran tunggal. Pesan membawa alert_id, node_id, schema_version dan event revision; isi detail diambil dari backend/cache sesuai izin.
Notifikasi yang datang terlambat diberi label waktu kejadian; jangan membuat alert baru setiap kali push yang sama diterima atau membuka layar.
Backend terpercaya mengirim FCM; service-account/server key tidak masuk APK/gateway. Token FCM terikat user+device+assignment dan diperbarui/dihapus saat refresh/logout.
Subscription topic publik `disaster_alerts` tidak membatasi siapa dapat membaca node. Untuk data privat, backend mengirim ke token pengguna yang berwenang; rules tetap membatasi pengambilan detail.

| Kondisi app | Perilaku | Navigasi dan dedupe |
| --- | --- | --- |
| Foreground | Update alert stream; tampilkan banner/in-app log; local notification hanya sesuai preferensi | Hindari duplicate OS/local dari message_id+alert_id+revision; user memilih membuka detail |
| Background | Handler top-level entry point memproses pekerjaan singkat yang diizinkan OS; notification payload memakai OS notification | `onMessageOpenedApp` membuka intent setelah auth/router siap |
| Terminated/cold start | Baca `getInitialMessage` dan launch-details local notification | Simpan pending intent nonsensitif; satu navigasi setelah session/registry initialized |
| Permission ditolak | Alert dalam app tetap berfungsi; status `Push dinonaktifkan oleh izin OS` | CTA Settings, tanpa meminta ulang pada setiap startup |
| Offline saat tap | Buka cache alert dengan label usia atau recovery screen jika belum cached | Setelah online fetch alert_id, jangan trigger command dari payload push |
| Logout/role dicabut | Jangan memperlihatkan detail alert lintas akun | Login lalu validasi assignment; unauthorized → penjelasan tanpa data sensitif |

Backend sender, message handling dan navigasi perlu implementasi terpisah; kode sekarang baru initialize channel/subscribe dan background handler kosong. [Firebase FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages).
Android 13+ dan platform lain memerlukan alur izin sesuai OS. Request critical alert iOS bukan hak yang otomatis tersedia; jangan menjanjikan bypass silent mode tanpa entitlement dan uji.
Channel peringatan berisi label/deskripsi jelas; pengguna dapat mengubah suara/getar di OS. Tidak ada bunyi atau getar pada setiap sampel telemetry.
Mute push adalah preferensi penerimaan notifikasi, tidak mematikan alarm hardware; copy dan ikon membedakan keduanya.

## 9. Offline-first, cache dan sinkronisasi

### 9.1 Keputusan penyimpanan

Gunakan SQLite sebagai satu cache persisten aplikasi dengan `sqflite` + `path` yang perlu ditambahkan; jangan menjalankan SQLite dan Isar secara paralel sebagai dua sumber kebenaran.
SQLite dipilih untuk history berurutan, indeks waktu, unique key dedupe, transaksi registry/latest/alerts dan migrasi yang eksplisit. Isar menawarkan model objek/reaktivitas tetapi menambah generator serta evaluasi kompatibilitas/platform; tidak diperlukan untuk lingkup ini.
RTDB tetap remote transport dengan cache memori SDK. Jangan mengaktifkan disk persistence SDK sekaligus cache SQLite; konfigurasi ditetapkan sebelum database digunakan dan diuji saat cold boot.
SDK RTDB dapat mengantre write saat offline, sehingga menonaktifkan disk persistence saja tidak cukup untuk keamanan command; semua aktuasi tetap melalui endpoint online dan server expiry. [Firebase offline capabilities](https://firebase.google.com/docs/database/flutter/offline-capabilities).

| Tabel lokal | Kunci/indeks minimum | Kebijakan target |
| --- | --- | --- |
| `registry_nodes`, `registry_gateways` | account/site + ID, registry revision | Cache metadata, revalidate saat login/resume; TTL verifikasi 24 jam sebagai default produk |
| `latest_telemetry` | account/site + node_key; event unique key | Simpan terakhir; freshness R/J terpisah dari retention |
| `telemetry_history` | event identity, node_key+received_at | Retensi default 7 hari; cap total awal 100.000 baris/50MB, ukur dan sesuaikan sebelum rilis |
| `alerts` | account/site+alert_id, revision, received_at | Retensi lokal 30 hari; unresolved tetap dipertahankan sampai batas kapasitas dengan peringatan |
| `command_snapshots` | command_id, revision | Audit/status baca saja; tidak ada kolom antrean submit otomatis |
| `sync_cursors`, `preferences` | account/site+stream key | Cursor server, schema/cache version, last successful sync, preferensi nonsensitif |

TTL 24 jam tidak mengubah metadata menjadi fresh tanpa server; label `Registry perlu diverifikasi ulang` setelah lewat TTL. Telemetry dapat disimpan 7 hari tetapi berstatus stale/missing jauh sebelumnya sesuai R/J.
Unresolved yang melebihi cap tidak dibuang diam-diam: simpan identitas/status minimum, tampilkan cakupan cache dan ambil detail online. Alert cloud/audit tidak dihapus oleh pruning lokal.
SQLite menyimpan telemetry nonsensitif dan metadata yang diperlukan. Token auth memakai penyimpanan SDK/platform yang sesuai; password WiFi/PoP/service secret tidak masuk database.
Data lokal dipartisi per akun/site; logout membersihkan atau mengunci namespace sebelum login akun lain. Access revoked membersihkan cache scope tersebut pada verifikasi berikutnya.

### 9.2 Alur repository dan konsistensi

Startup membaca cache milik user yang sah → render dengan provenance offline/cache → autentikasi/registry → bounded remote query → transaksi upsert SQLite → emit view model.
Remote empty snapshot harus mengirim list kosong; parser error/onError harus menghasilkan status error dengan request ID, bukan catch kosong yang meninggalkan data lama terlihat fresh.
Query history berdasarkan node_key dan received_at, page terbatas dengan cursor unik; `.indexOn` dan hak akses path harus disiapkan server. Jangan subscribe seluruh history selamanya.
Incremental sync memakai revision/cursor server dan overlap window terkontrol, bukan jam HP sebagai cutoff. Dedupe berdasarkan identitas event; latest ditentukan server order/revision.
Saat history backfill, gabungkan per batch dalam transaksi; update chart dibatasi cadence UI agar tidak rebuild seluruh layar tiap paket.
Pull-to-refresh mempunyai timeout, hasil eksplisit dan retry; background sync mobile adalah best effort OS, bukan janji listener terus hidup saat terminated.
Reconnect otomatis hanya membaca/sinkronisasi idempotent dengan exponential backoff+jitter dan batas percobaan; credential invalid berhenti dan meminta login.
Offline edits metadata/calibration/ack tidak diantrekan pada versi ini. Simpan draft lokal nonsensitif boleh, tetapi submit baru memerlukan user review setelah online.
Cache schema menggunakan PRAGMA user_version, migrasi transaksional, serta test upgrade. Remote schema_version unsupported ditandai incompatible tanpa mengisi default pengukuran.
Jika migrasi gagal, pertahankan salinan lokal yang dapat dipulihkan dan tampilkan recovery; telemetry cache yang aman dapat diunduh ulang, tetapi jangan menghapus draft diam-diam.
Storage penuh: hentikan insert history lama, prioritaskan latest/alert, tampilkan banner dan aksi bersihkan cache dengan ringkasan cakupan. Clear cache tidak menghapus data server.
Mode DEMO memakai repository/namespace terpisah dan watermark pada seluruh screen/chart/export; pergantian mode menutup subscription live/dedupe berbeda tanpa mengubah data server.

## 10. Riverpod, keamanan dan adaptasi kode nyata

Repository interface target: watchRegistry, watchGatewayHealth, watchNodes, watchNode, queryHistory, watchAlerts, watchCommand, refresh, dan submitCommand online. Hasil membawa provenance, quality, schema dan sync metadata.
Provider yang disarankan: dataSourceModeProvider, authSessionProvider, siteScopeProvider, connectivityProvider, gatewayHealthProvider, nodeListProvider, nodeDetailProvider(id), telemetryHistoryProvider(query), alertsProvider(filter), commandControllerProvider(id), provisioningControllerProvider.
Pisahkan AsyncValue loading/error dari stale/cache: data cached dapat hadir bersamaan dengan remote error. Freshness dihitung provider domain memakai R/J, bukan getter 8 jam di model.
Provider family key mencakup account/site/node/query; dispose membatalkan stream, discovery dan request yang tidak relevan. Hindari repository dibuat ulang setiap build tanpa lifecycle jelas.
Command controller mempertahankan command_id saat sheet ditutup dan tidak mengulangi side effect dari rebuild. Provisioning controller menyimpan tahap/sesi dan memisahkan efek native dari UI.
Riverpod mendukung binding asynchronous/pull refresh; gunakan API yang kompatibel dengan 2.5.x dan jangan menyalin generator Riverpod 3 tanpa migrasi. [Referensi pemelihara 2.5.1](https://pub.dev/packages/flutter_riverpod/versions/2.5.1).
Auth wajib untuk LIVE; Firebase Authentication/session dan backend memvalidasi role/scope. Rules menolak akses silang site, penulisan telemetry oleh app operator, dan perubahan command result oleh client.
Pisahkan permission observasi, operator-command, commissioning dan admin pada enum role `viewer/operator/engineer/admin`; satu role tidak otomatis mewarisi semua fitur. Hak final diputus server, bukan flag tersembunyi di UI.
Backend memvalidasi schema, unit/range, expiry, idempotency dan transisi status; rules mengindeks path yang diperlukan. Emulator test mencakup deny-by-default dan assignment dicabut. [Firebase Rules + Auth](https://firebase.google.com/docs/rules/rules-and-auth).
Log error menyimpan kode/request ID tanpa token, password, koordinat pribadi atau payload rahasia. Diagnostic export melalui aksi eksplisit dan redact sebelum berbagi.

| File nyata di `titen_app/` | Perubahan implementasi yang diperlukan |
| --- | --- |
| `lib/core/constants/app_colors.dart`, `app_typography.dart`, `core/theme/titen_theme.dart` | Terapkan token dokumen 01, dark/light system, bundle font dan ukuran adaptif |
| `lib/core/router/app_router.dart`, `core/widgets/responsive_shell.dart` | Empat tab mobile, route compatibility, guard auth/intent dan breakpoint bersama |
| `lib/features/dashboard/data/models/sensor_node.dart` | Nullable metadata/measurement; hapus lokasi/baterai/RSSI/time palsu dan getter online 8 jam |
| `lib/features/dashboard/data/models/telemetry_data.dart` | Nullable field, quality, event identity, observed_at/received_at; jangan default null menjadi 0/25/50 |
| `lib/features/dashboard/data/models/alert_model.dart` | Level/lifecycle/evidence valid; hapus default `[1,2]`, lokasi dan AWAS sintetis |
| `lib/features/dashboard/data/repositories/firebase_node_repository.dart` | Adapter v1/v2, onError/empty emission, real history, registry, SQLite sync, tanpa mock fallback |
| `lib/features/dashboard/data/repositories/node_repository.dart` | Interface typed command/provisioning capability, sync/provenance dan paginated history |
| `lib/features/dashboard/data/repositories/mock_node_repository.dart` | Fixture DEMO saja; source sintetis eksplisit; tidak dipanggil repository LIVE |
| `lib/features/dashboard/application/dashboard_providers.dart` | Source enum, unknown/loading terpisah, level unresolved dihormati, freshness provider |
| `lib/features/dashboard/presentation/dashboard_screen.dart` | Home health berdasarkan registry, tanpa hitungan online/AMAN saat sumber gagal |
| `lib/features/sensors/presentation/sensor_list_screen.dart`, `sensor_detail_screen.dart` | Komponen M06/M09–M14, nilai null, radio registry, sparkline asli dan kontrol terkonfirmasi |
| `lib/features/analytics/application/analytics_providers.dart`, `presentation/analytics_screen.dart` | Query history asli dan coverage; hapus generator sinus/angka simulasi dari LIVE |
| `lib/features/settings/application/settings_providers.dart` | Hapus status ONLINE, 915MHz, empat node dan statistik statis; konsumsi gateway health |
| `lib/features/emergency/application/emergency_providers.dart`, `presentation/emergency_screen.dart` | Command lifecycle+ACK, role, durasi/expiry, tanpa sukses hanya dari write database |
| `lib/core/services/notification_service.dart`, `lib/main.dart` | Background init, token refresh/logout, permission context, foreground dedupe, cold navigation |
| `lib/core/widgets/pin_modal.dart`, `threat_simulator_bar.dart` | Ganti PIN statis dengan auth/reauth server; simulator hanya namespace DEMO |
| File baru `core/data/local/`, `features/provisioning/`, `features/commands/` | Cache schema/repository, native provisioning adapter, typed command controller dan audit read model |
| `pubspec.yaml`, Android manifest/native adapter, tests | Dependency tambahan terversi, bundled assets, izin minimal dan integrasi perangkat nyata |

## 11. Prinsip native, aksesibilitas dan feedback

Gunakan bottom sheet adaptif untuk detail measurement/filter/konfirmasi singkat, full-screen flow untuk wizard panjang. Sheet radius10, header tetap, konten scroll, tombol tidak tertutup keyboard.
Swipe-to-dismiss hanya menutup sheet/pesan nonkritis; command yang sedang berjalan tetap memiliki halaman status. Gesture Android Back mematuhi penjagaan draft/provisioning yang jelas.
Semua aksi sentuh minimal 48×48dp termasuk ikon refresh, chevron, pilihan grafik, close sheet dan target map. Ukuran ikon boleh 20dp tetapi hit area tetap 48dp.
Teks penting menargetkan kontras ≥7:1 pada latar aktual untuk light/dark; angka warna token saja tidak membuktikan AAA. Uji rendered state, disabled yang perlu dibaca, overlay, chart tooltip dan pressed/focus.
Kontrol/focus/batas bermakna diuji kontras nonteks; jangan menjadikan amber/emerald/rose saturasi rendah sebagai teks tanpa validasi. Icon+label/status memastikan pemahaman tanpa warna.
Font scale 200% wajib: line wrap, single-column, tile tinggi intrinsik, sheet dapat scroll. Dilarang clamp TextScaler atau memakai ellipsis untuk nilai/alasan kegagalan utama.
TalkBack/VoiceOver membaca `Node 01, suhu belum tersedia, waktu observasi tidak diketahui`, bukan hanya `—`. Pair unit dengan angka; exclude sparkline dekoratif jika tabel alternatif sudah tersedia.
Semantics pada relay membedakan `Keadaan aktual belum diketahui` dan `Permintaan ON sedang diproses`; jangan announce switched-on sebelum hasil perangkat.
Live region hanya untuk perubahan penting: koneksi gagal, alert baru, command terminal. Update setiap sampel tidak menyebabkan pembaca layar berbicara tanpa henti.
Focus order mengikuti pembacaan; focus kembali ke trigger saat sheet tutup. Keyboard Enter/Space menjalankan aksi yang tepat; Escape/back menutup UI dengan aman.
Animasi transisi 120–180ms dan skeleton tidak berkedip; preferensi reduce motion mematikan animasi dekoratif. Grafik tidak memindahkan layout saat paket baru tiba.
Haptic navigation opsional berintensitas ringan; haptic relay sukses mengikuti ACK valid. Tidak ada sound/glow/getar setiap sampel. Notifikasi mengikuti preferensi OS serta pengguna.
Uji landscape, display scaling, font 200%, dark/light, grayscale, screen reader dan keyboard fisik. Panduan Flutter menjelaskan dukungan accessibility dan target sentuh; spesifikasi TITEN memakai target teks lebih ketat. [Flutter accessibility](https://docs.flutter.dev/ui/accessibility).

## 12. Gerbang penerimaan dan urutan implementasi

Semua angka performa di bawah merupakan target uji prototipe, bukan hasil pengukuran saat ini. Catat model HP, OS, APK/firmware/backend version, jaringan dan bukti log saat menguji.

| ID / prioritas | Skenario | Kriteria lulus |
| --- | --- | --- |
| A01 P0 | Cold start tanpa registry/telemetry | Unknown/empty yang benar, tanpa nilai/koordinat/count palsu atau banner Aman |
| A02 P0 | Satu paket fisik Node 01 | ID, measurement, unit dan timestamp detail/history cocok log gateway; mode LIVE terlihat |
| A03 P0 | Sensor putus atau field null/range invalid | Field error/unknown, field sah tetap tampil; zero tidak disamakan dengan null |
| A04 P0 | R/J terlewati, jam HP bergeser, node maintenance | Fresh/stale/missing/unknown sesuai kontrak; planned sleep tidak keliru offline |
| A05 P0 | History kosong/satu titik/gap/duplikat/out-of-order | Tidak muncul kurva sintetis, gap terputus, latest tidak mundur, event dedupe |
| A06 P0 | Command tanpa capability/role/internet | Kontrol disabled+alasan; server menolak bypass; tidak ada offline queue |
| A07 P0 | ON/OFF, ACK transport saja, ACK salah/terlambat | Hanya device result valid mengubah reported output; timeout/failed/expired terlihat |
| A08 P0 | Double tap, timeout submit, app mati setelah submit | Satu command ID/idempotency; resume query status; tidak aktuasi ganda |
| A09 P0 | Alert level1/2/3, unresolved dan unknown | Level asli dipertahankan, ack berbeda resolve, evidence/source benar |
| A10 P0 | Push foreground/background/cold/tap offline | Satu alert, intent ke detail benar setelah auth; izin ditolak tetap ada log in-app |
| A11 P1 | Internet mati saat cache tersedia/kosong | Cache terbaca dan berlabel, state lama tidak hijau-current; retry tidak menghapus data |
| A12 P1 | Reconnect/backfill/role revoked/logout akun lain | Sync tanpa duplikasi, scope terisolasi, akses/command dicabut server |
| A13 P1 | BLE unsupported/permission denied/proof salah | Tidak mengirim kredensial; tahap/alasan/pemulihan jelas |
| A14 P1 | Provisioning salah password/drop BLE/cancel/app mati | Config lama pulih bila rollback ACK; unknown jujur; cloud claim hanya setelah validasi |
| A15 P1 | SQLite migration/storage full/pruning | Latest/alert diprioritaskan, coverage cache jelas, tidak kehilangan data server/draft diam-diam |
| A16 P1 | Font200%, target48dp, TalkBack, kontras | Tidak overflow/kontrol tersembunyi; semantics benar; hasil audit kontras tercatat sebelum klaim AAA |
| A17 P1 | Sesi DEMO → LIVE dan sebaliknya | Semua fixture berlabel sintetis; subscription/cache terpisah; command hardware tidak berjalan di DEMO |
| A18 P1 | Demo fisik dari boot hingga alert dan relay | Skenario berulang dengan bukti paket/cloud/HP/ACK; seluruh batas kemampuan dijelaskan |

Urutan kerja: (1) freeze schema/registry/RJ dan rules, (2) model nullable+adapter+real history, (3) Home/list/detail dan shell, (4) command backend+device ACK, (5) FCM lifecycle, (6) SQLite/reconnect, (7) wizard provisioning setelah firmware siap, (8) aksesibilitas dan rehearsal fisik.
Sebelum mengumumkan selesai, compile APK, jalankan analyzer/test yang relevan, uji emulator rules/backend, lalu uji HP+gateway+node asli. Widget test saja tidak membuktikan radio, push background, feedback relay atau provisioning aman.
Dokumen ini siap menjadi backlog implementasi; status gerbang di atas tetap belum terverifikasi sampai hasil pengujian disimpan bersama versi dan bukti.
