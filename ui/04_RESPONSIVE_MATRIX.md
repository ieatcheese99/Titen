# TITEN — Matriks Responsif, Ergonomi, dan Aksesibilitas

Versi: **1.0 · 7 Oktober 2026 · Asia/Jakarta**. Status: spesifikasi implementasi; bukan bukti fitur sudah berjalan atau hasil uji perangkat.

Dokumen ini melengkapi [Design System](01_DESIGN_SYSTEM.md), [Web Spec](02_WEB_SPEC.md), dan [Flutter Spec](03_APP_FLUTTER_SPEC.md). Kata **wajib** adalah kriteria penerimaan. Pembahasan rangkaian, charging, regulator, dan perubahan hardware power ditunda sesuai permintaan pengguna. Ringkasan baterai hanya ditampilkan bila telemetrinya tersedia dan valid.

## 1. Kontrak dasar

- Gunakan satu identitas visual utilitarian: zinc netral, Inter untuk UI, JetBrains Mono untuk ID/angka teknis; font dibundel agar layout tidak bergantung koneksi font eksternal.
- Ambil warna dari token `surface.canvas/panel/subtle`, `text.primary/secondary/metadata`, `border.subtle/control/focus`, dan `semantic.normal/warning/critical/syncing/unknown` pada dokumen 01. Varian semantik menyediakan `fg/bg/border`.
- Radius hanya 6, 8, atau 10 unit logis; border 1 unit; jarak mengikuti grid 4/8. Hindari glow, gradien dekoratif, glass blur, bayangan besar, dan kartu tanpa fungsi.
- Struktur, identitas node, urutan tingkat bahaya, kebijakan command, dan arti warna harus sama pada semua ukuran. Layout boleh berubah; hak akses tidak berubah karena ukuran layar.
- Tampilan LIVE tidak boleh mengisi nilai hilang dengan angka contoh, lokasi dugaan, timestamp sekarang, atau status AMAN. Data kosong adalah **Belum ada data**.
- Contoh dalam dokumen menggunakan `node_id: 1` yang ada pada basis firmware/model proyek, diserialisasi menjadi `node_key: node_01` dan label **Node 01**. `—` berarti belum tersedia; contoh tersebut bukan klaim pengukuran fisik.
- Tema mengikuti pengaturan sistem dan dapat dipilih manual. Semua state, termasuk error, fokus, drawer, dan chart, diuji pada dark serta light mode.

### 1.1 Kondisi kode yang perlu dimigrasikan

| Bukti lokal saat spesifikasi dibuat | Implikasi implementasi |
| --- | --- |
| `titen_app/lib/core/widgets/responsive_shell.dart` membatasi konten ke 1440 tetapi belum memilih tiga mode layout | Tambahkan kontrak breakpoint di shell; batas lebar bukan implementasi responsif lengkap |
| `dashboard_screen.dart` memakai `constraints.maxWidth > 750` | Ganti keputusan shell dengan breakpoint dokumen ini; keputusan grid internal tetap berbasis ruang konten |
| `index.css` membatasi prototipe web ke 440 dan memakai media query 480 | Web observabilitas perlu shell desktop/tablet nyata; jangan membesarkan frame ponsel saja |
| Model saat ini memberi fallback baterai, RSSI, koordinat, status, dan waktu | Perkenalkan nilai nullable/validitas sebelum mengklaim LIVE; ukuran layar tidak mengoreksi data palsu |
| Audit belum membuktikan uploader gateway, provisioning, notifikasi, dan command ACK fisik | Tampilkan capability **Belum didukung** sampai backend/firmware teruji |

## 2. Breakpoint dan satuan

`w` adalah lebar layout yang benar-benar diberikan kepada shell. Pada web gunakan **CSS logical pixels** dari layout viewport; pada Flutter gunakan **logical pixels/dp** dari constraint root window. Lebar fisik layar, DPI, nama perangkat, dan sistem operasi tidak menentukan breakpoint.

| Mode | Predikat tepat | Grid konseptual | Gutter konten | Gap | Navigasi utama |
| --- | --- | --- | --- | --- | --- |
| Mobile | `w < 640` | 4 kolom; konten umumnya satu stack | 16; boleh 12 pada 320 | 12–16 | Web: top bar + menu overlay; Flutter: bottom navigation |
| Tablet | `640 <= w <= 1024` | 8 kolom; satu/dua pane bila muat | 24 | 16 | Web: rail 72 + menu; Flutter: rail adaptif atau bottom navigation bila ruang sempit |
| Desktop | `w > 1024` | 12 kolom; multi-pane | 24–32 | 16–24 | Sidebar 240, dapat diciutkan menjadi 72 |

- **1024 termasuk tablet**, 1025 termasuk desktop; nilai pecahan seperti 1024,5 juga desktop. Jangan menggeser batas ke 1024 demi default framework.
- Implementasi web harus membagi rentang tanpa celah pecahan: mobile `width < 640px`, tablet `640px <= width <= 1024px`, desktop `width > 1024px`, atau logika ekuivalen yang sama tepatnya.
- Flutter memakai perbandingan constraint yang sama. Jangan menggandakan aturan `isPhone`, `isTablet`, atau breakpoint 750 pada halaman lain.
- Shell memilih navigasi dari lebar root. Grid di dalam drawer/chart memilih jumlah kolom dari constraint lokal; drawer sempit tidak mengubah navigasi global.
- Sidebar expanded/collapsed mengubah ruang canvas, bukan identitas breakpoint. Grid memakai minimum card 240; turun jumlah kolom jika tidak muat.
- Maksimum canvas umum 1600. Pada layar lebih lebar, pusatkan canvas; halaman log boleh memakai ruang tambahan bila pilihan kepadatan pengguna mengizinkan.
- Lebar 320 CSS px adalah baseline minimum web yang wajib dapat dipakai. Di bawah 320 tetap pertahankan alur kritis dengan stack dan scroll vertikal; jangan memblokir akses.
- Perubahan orientasi, browser zoom, split view, dan resize window harus menghitung layout ulang tanpa kehilangan filter, node terpilih, draft form, atau command ID.
- Pergantian layout tidak membuat subscription/listener ganda, memuat ulang command, atau menghapus hasil yang masih ditunggu. Simpan state domain di luar widget/panel responsif.

## 3. Mode data, koneksi, kesegaran, dan bahaya

Mode sumber adalah `LIVE` atau `DEMO`. `OFFLINE` adalah keadaan transport/cache yang dapat terjadi ketika sumber LIVE dipilih; jangan menyamakan cache dengan sumber simulasi. Header dapat menampilkan **LIVE · OFFLINE · Cache** atau **DEMO · Simulasi**.

| Dimensi | State | Penyajian yang wajib |
| --- | --- | --- |
| Sumber | LIVE | Hanya data perangkat/backend asli; label LIVE tidak membuktikan koneksi sehat |
| Sumber | DEMO | Label Simulasi pada header, card, chart, export; seluruh command diarahkan ke simulator terisolasi |
| Transport | online / reconnecting / offline / unknown | Label teks + ikon; status koneksi ke server terpisah dari gateway dan node; Menghubungkan adalah label proses, bukan enum perangkat baru |
| Kesegaran | fresh / stale / missing / unknown | Tampilkan waktu penerimaan terakhir dan status; jangan hilangkan nilai historis yang masih berguna |
| Siklus perangkat | unregistered / provisioning / active / planned_sleep / maintenance / revoked | Tidur/maintenance mengikuti jadwal registry; tidak menjadikan sampel lama sebagai data fresh |
| Bahaya | belum diketahui / Aman / Waspada / Siaga / Awas | Hanya dari evaluasi data valid; bahaya terakhir tetap terlihat saat koneksi hilang dengan label data lama |
| Command | requested / accepted / executing / succeeded / failed / expired / cancelled | State memiliki ID, waktu, target, dan hasil; write database bukan keberhasilan perangkat |

Aturan kesegaran menggunakan `R = registry.expected_report_interval_ms` dan `J = delivery_grace_ms`. `R` adalah cadence laporan/upload, bukan interval sampling sensor. Usia dihitung `age = max(0, server_now - received_at)` dari waktu penerimaan yang otoritatif dan offset jam server yang diketahui; jam tidak dipercaya menghasilkan unknown.

| Kondisi | Hasil |
| --- | --- |
| Timestamp/config belum ada atau jam tidak dapat dipercaya | `unknown`: **Kesegaran belum dapat dinilai** |
| `age <= R + J` | `fresh`: **Data terbaru** |
| `R + J < age <= 3R + J` | `stale`: **Data terlambat** |
| `age > 3R + J` | `missing`: **Laporan belum diterima**; jangan otomatis menyebut perangkat offline |
| Jadwal tidur/maintenance yang terdaftar masih berlaku | Lifecycle `planned_sleep/maintenance` dan `next_expected_at`; dikecualikan dari alarm kehilangan laporan yang memang diharapkan; freshness sampel tetap dinilai terpisah |
| Bukti server/disconnect atau jadwal koneksi yang ditetapkan menyatakan offline | Status koneksi perangkat `offline`; tetap tampilkan kesegaran dan bahaya secara terpisah |

Threshold perlu berasal dari konfigurasi proyek yang dikunci. Jangan mempertahankan indikator online delapan jam pada demo dengan laporan pendek. Pada semua ukuran, contoh tanpa bukti adalah **Node 01 · Koneksi belum diketahui · Data belum tersedia · Bahaya belum diketahui**.

Field domain bahaya adalah `hazard_level` dan `hazard_type` sesuai kontrak dokumen 01; `status_level` firmware lama hanya dibaca melalui adapter. `source` hanya `live/demo`; cache dicatat sebagai metadata penyimpanan/transport, bukan enum sumber ketiga.

## 4. Matriks layout utama

| Area | Mobile <640 | Tablet 640–1024 | Desktop >1024 |
| --- | --- | --- | --- |
| Top bar | Min 56 tinggi; menu, judul singkat, mode; status dapat menjadi baris kedua | Min 64; judul + status; tindakan sekunder di overflow | Min 64; breadcrumb, mode, status, pencarian |
| Sidebar/navbar | Menu web overlay; native 3–5 destinasi dengan ikon dan label | Rail 72 jika muat; drawer berlabel saat diperluas | Sidebar 240/72, tooltip hanya pelengkap label aksesibel |
| Banner koneksi/bahaya | Full width, teks wrap, satu CTA per baris | Full width; CTA samping bila muat | Full width di atas canvas; tidak mengganti status masing-masing node |
| Ringkasan telemetri | Satu kolom; dua hanya bila tiap card >=240 dan teks tetap muat | Dua kolom; turun ke satu saat text scale besar | Dua–empat kolom menurut ruang canvas; maksimum empat |
| Topologi | Daftar node menjadi default; tombol buka kanvas topologi | Kanvas dan daftar melalui tab; split bila pane cukup | Kanvas topologi + daftar/detail; hubungan radio hanya dari metadata nyata |
| Peta geografis | Buka dari lokasi node; tombol zoom dan daftar pengganti | Peta 320 tinggi minimum jika cukup ruang | Peta 360–480 tinggi; detail drawer mengurangi ruang canvas |
| Tabel node | Card stack dengan label field | Tabel kolom prioritas atau card jika tidak muat | Tabel lengkap; pilih kolom; row dengan tindakan min 48 tinggi |
| Log stream | Ringkasan card, detail payload lewat sheet | Waktu/level/node/pesan; metadata di detail | Tabel waktu/level/node/pesan/transport; payload expandable |
| Grafik | Satu panel; periode singkat; legend wrap; tabel data alternatif | Dua panel jika masing-masing >=320; jika tidak, stack | Panel terpisah per metrik; tidak mencampur satuan berbeda dalam satu plot |
| Filter | Tombol Filter dengan jumlah aktif; sheet berisi field stack | Drawer/filter bar wrap | Toolbar satu/dua baris; field tidak dipaksa mengecil |
| Detail node | Halaman terpisah atau sheet penuh yang dapat discroll | Drawer 400–480 atau pane bila sisa daftar >=320 | Drawer 420–480; dapat dipin jika sisa canvas >=640 |
| Konfirmasi command | Sheet/action page dengan teks target dan hasil | Dialog 440–560 atau sheet sesuai tinggi window | Dialog 440–560, fokus terkelola, tombol hardware min 48 |
| Provisioning | Wizard native satu langkah per halaman | Wizard native dengan ringkasan samping jika muat | Web menampilkan status capability/petunjuk jalur yang tersedia |
| Export | Tombol di menu tindakan; status download terlihat | Toolbar/overflow | Toolbar; opsi data lengkap dan schema export |
| Toolbar aksi hardware | Area detail dekat bawah dengan safe area dan ruang konten | Pada pane detail; bukan di tengah garis pemisah pane | Pada detail node; jangan menaruh ON di tiap baris tabel padat |

Tinggi di tabel adalah baseline, bukan tinggi tetap saat teks membesar. Tidak boleh memaksa semua informasi memenuhi satu layar tanpa scroll.

## 5. Mobile web dibanding Flutter native

| Tugas | Browser smartphone | Flutter native |
| --- | --- | --- |
| Prioritas | Observabilitas ringkas, audit, cek satu node, tindakan terbatas sesuai role | Tugas lapangan, inspeksi sensor, provisioning, kontrol yang jelas |
| Overview | Card stack dengan bahaya/kesegaran paling atas | Health check gateway dan node; shortcut tugas lapangan |
| Kontrol hardware | Boleh untuk operator terotorisasi jika target/capability/konfirmasi/ACK terpenuhi | Aturan sama, dengan haptic tambahan bila tersedia |
| Batas tindakan | Tanpa bulk ON dari card ringkasan; tindakan satu node lewat detail | Tindakan satu node; bulk hanya fitur terpisah bila spesifikasi backend mendukung |
| Koneksi buruk | Cache jika implementasi menyediakan; tampilkan umur dan sumber cache | Cache persisten; baca data terakhir dan panduan lokal |
| Saat offline | Tidak mengirim, menyimpan untuk replay, atau menjadwalkan command hardware | Sama; pengguna harus mengonfirmasi command baru setelah tersambung |
| Provisioning BLE | Bukan kemampuan yang dijanjikan untuk seluruh browser | Hanya aktif bila firmware, plugin, izin, dan perangkat mendukung |
| Jalur provisioning alternatif | Petunjuk AP fisik/WiFi hanya bila gateway mengimplementasikan metode itu | Dapat menawarkan AP yang didukung ketika BLE gagal; tanpa klaim capability palsu |
| Refresh | Tombol Muat ulang jelas; browser pull-to-refresh bukan satu-satunya jalur | Pull-to-refresh + tombol aksesibel; tidak menggandakan stream subscription |
| Notifikasi | Status izin dan kemampuan browser; tidak dianggap setara push native otomatis | Deep link alert ke node, termasuk ketika app dibuka dari background |
| Sentuhan/keyboard | Touch, pointer, dan keyboard; tidak bergantung hover | Touch utama; keyboard, mouse/stylus tablet, dan screen reader tetap didukung |

Browser kecil tidak otomatis menjadi readonly. Pemisahan berlandaskan kemampuan runtime, role, dan keselamatan command. Status offline, izin tidak cukup, capability belum ada, atau target tidak diketahui memang membuat kontrol tidak dapat dikirim.

## 6. Kontrak komponen responsif

Semua komponen memakai token dokumen 01. Nilai dimensi di bawah adalah unit logis. Semua tindakan interaktif menyediakan target minimal **48×48**, label aksesibel, fokus terlihat, serta urutan baca yang mengikuti DOM/semantics.

Tipografi responsif menggunakan `type.body/type.control` untuk dense desktop, `type.bodyComfortable/type.controlComfortable` 16/24 untuk mobile dan tugas touch, serta `type.metadata` minimal 13/20 pada mobile. Angka font 14/16 pada tabel komponen berarti desktop/touch; font teknis tetap `type.technical` dan mengikuti scaling sistem.

Loading memakai skeleton bentuk netral tanpa angka, dengan status sedang memuat yang dapat dibaca screen reader. Loading, empty, sensor-invalid, transport-error, dan data-lama adalah state berbeda; skeleton berhenti saat error dan tidak berkedip terus ketika koneksi buruk.

### 6.1 Adaptive Navigation

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Berpindah Overview, Nodes, Alerts, Logs, dan Settings tanpa menghapus filter halaman |
| Visual | `surface.panel`, border `border.subtle`, Inter 14/16, radius 6; active memakai teks dan indikator border, bukan warna saja |
| Default | Destinasi aktif memiliki label/current-page; menu tertutup pada mobile web |
| Hover / Active | Hover `surface.subtle` untuk pointer; fokus `border.focus`; active tidak memicu perpindahan dua kali |
| Disabled | Destinasi tanpa izin menampilkan alasan di menu yang dapat dibaca; jangan menyembunyikan seluruh konteks pengguna |
| Error / Alert | Jumlah alert hanya jika data valid; badge jumlah tidak mengganti judul Alerts; status tidak terbaca ditulis eksplisit |
| Contoh nyata | Overview → Nodes → **Node 01**; badge alert **—** ketika backend belum memberi jumlah |

### 6.2 Mode and Connection Banner

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Membedakan sumber data, transport, cache, dan pemulihan koneksi |
| Visual | `surface.subtle`, Inter 14/16, radius 6; syncing sky, warning amber, unknown zinc, offline terkonfirmasi critical; gunakan token semantik lengkap |
| Default | **LIVE · Menunggu data** dengan waktu terakhir **—**; ukuran menyesuaikan teks, bukan tinggi tetap |
| Hover / Active | Tombol Coba lagi memiliki hover/fokus; active menunjukkan proses koneksi, tidak mengklaim koneksi sudah pulih |
| Disabled | Coba lagi tidak dapat diulang saat satu proses koneksi berjalan; label **Menghubungkan…** |
| Error / Alert | **OFFLINE · Menampilkan cache** beserta waktu; retry tetap dapat diakses, alert bahaya lama tetap terlihat |
| Contoh nyata | **LIVE · Koneksi gateway belum terverifikasi · Data terakhir: —** |

### 6.3 Node Table / Node Card

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Memilih node dan membandingkan kesehatan tanpa kehilangan detail saat tabel menjadi card |
| Visual | `surface.panel`, border 1 `border.subtle`, radius 8, Inter 14/16; ID dan angka JetBrains Mono; gap 12/16 |
| Default | ID, bahaya, kesegaran, koneksi, dan tombol Detail tersedia; card tidak seluruhnya berperilaku sebagai switch relay |
| Hover / Active | Row/card hover subtle; pilihan aktif memiliki border kontrol dan teks Terpilih; fokus masuk ke link Detail |
| Disabled | Field belum tersedia memakai **—** + alasan; data sensor tidak menjadikan link detail disabled |
| Error / Alert | Sensor gagal ditulis dekat field; AWAS tetap berlabel teks; data lama tidak berubah menjadi AMAN |
| Contoh nyata | **Node 01 · Sudut: — · RSSI: — · Belum ada paket tervalidasi** |

### 6.4 Topology / Map View

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Memahami hubungan node–gateway dan lokasi yang benar-benar diketahui |
| Visual | Kanvas `surface.panel`, garis `border.control`, radius 8; marker ikon + label; tombol zoom/reset 48×48 |
| Default | Topologi menunjukkan identitas dari registry; peta tidak memasang marker jika koordinat tidak tersedia |
| Hover / Active | Hover/fokus menampilkan nama, bukan satu-satunya akses detail; klik/tap memilih dan membuka detail yang setara |
| Disabled | Drag/zoom dinonaktifkan bila kanvas belum ada; tombol Daftar node tetap tersedia |
| Error / Alert | Tile gagal memiliki penjelasan dan retry; hubungan LoRa belum terbukti ditulis **Belum terverifikasi**, bukan garis hijau |
| Contoh nyata | **Node 01 · Lokasi belum dikonfigurasi**; jangan memakai koordinat fallback Bandung sebagai lokasi fisik |

### 6.5 Telemetry Chart and Data Table

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Melihat tren per sensor, gap laporan, dan nilai dengan unit serta sumber |
| Visual | Panel radius 8, Inter 13–14 label, mono angka; garis semantik dengan dash/label, bukan warna saja; legend wrap |
| Default | Tidak ada garis jika history belum tersedia; range, zona waktu, satuan, dan waktu terakhir terlihat |
| Hover / Active | Tooltip dapat dibuka pointer/fokus/tap; crosshair bukan satu-satunya cara memperoleh nilai; legend toggle punya pressed state |
| Disabled | Download disabled jika dataset kosong; tombol Tabel data tetap membuka pesan kosong aksesibel |
| Error / Alert | Gap data digambar sebagai gap, bukan interpolasi normal; query gagal menyisakan last result berlabel lama dan retry |
| Contoh nyata | **Sudut Node 01 (°) · Belum ada riwayat**; CSV tidak mengisi baris pengukuran fiktif |

### 6.6 Log Stream / Log Detail

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Audit paket, error integrasi, dan lifecycle perintah dengan identitas yang dapat ditelusuri |
| Visual | `surface.panel`, radius 6; pesan Inter 14, ID/payload mono 13; level memiliki ikon/label dan token warna |
| Default | Stream tidak autoscroll jika pengguna sedang membaca; tombol **Ada log baru** menunjukkan jumlah valid |
| Hover / Active | Baris aktif membuka detail; Pause/Resume stream tersedia dengan keyboard dan touch |
| Disabled | Export saat query berjalan memberi status; sumber log yang belum terintegrasi diberi keterangan |
| Error / Alert | Error koneksi bukan baris sukses; payload raw dapat dibuka dan disalin tanpa kehilangan timestamp/context |
| Contoh nyata | Filter **node_id = 1** dengan empty state **Belum ada log yang tersedia**; jangan mengarang MQTT event |

### 6.7 Filter and Export Panel

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Memilih node, periode, level log, dan sumber; mengunduh data yang sesuai filter dan hak akses |
| Visual | `surface.panel`, border kontrol 1, radius 6; Inter 14/16; field dan tombol min 48 tinggi; error inline rose |
| Default | Filter aktif diringkas dalam label dan count; zona waktu **Asia/Jakarta (UTC+07:00)** terlihat |
| Hover / Active | Apply menunjukkan loading, label filter hanya berubah setelah validasi; Reset dapat dioperasikan tanpa gesture |
| Disabled | Export belum tersedia jika integrasi tidak ada; bukan tombol aktif yang hanya menampilkan toast sukses |
| Error / Alert | Rentang terbalik, tanpa izin, dataset terlalu besar, dan timeout masing-masing memberi perbaikan yang konkret |
| Contoh nyata | **Node 01 · Semua level · Riwayat belum tersedia**; tanggal filter pengguna bukan timestamp hasil pengukuran |

### 6.8 Responsive Detail Drawer / Sheet

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Menampilkan detail node, konfigurasi, pinout read-only/terotorisasi, dan status command |
| Visual | `surface.panel`, border 1, radius 10 pada overlay; judul Inter 18/20; field 14/16; tidak memakai backdrop blur |
| Default | Drawer kanan desktop/tablet; halaman/sheet hampir penuh mobile; judul menyertakan target **Node 01** |
| Hover / Active | Handle bukan satu-satunya cara memperbesar; tombol Tutup 48; fokus ke heading lalu konten; return focus ke pemicu |
| Disabled | Simpan config tidak tersedia tanpa hak/capability; nilai lama tetap terbaca dengan alasan |
| Error / Alert | Error tampil dekat field dan ringkasan; perubahan belum tersimpan memiliki guard ketika ditutup |
| Contoh nyata | **Node 01 · Profil board belum dikonfirmasi · Pin flame acuan: GPIO7** dari audit, bukan klaim pin sudah terpasang |

### 6.9 Hardware Command Confirmation

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Mengirim satu tindakan eksplisit ke node yang benar, kemudian menunggu hasil perangkat |
| Visual | Panel radius 10, label Inter 16+, target node mono 16; tindakan berisiko `semantic.critical`, batal netral; gap antar tombol 16 |
| Default | Tampilkan target, aksi ON/OFF, durasi jika didukung, expiry, dan state perangkat yang diketahui; tidak memakai switch optimistis |
| Hover / Active | Tekan Konfirmasi hanya sekali; state requested menampilkan **Mengirim…**; haptic singkat hanya feedback interaksi |
| Disabled | Offline, role tidak cukup, target unknown, capability belum ada, atau command sedang berjalan; alasan terlihat sebelum tombol |
| Error / Alert | accepted **Diterima server**; executing **Menunggu hasil perangkat**; succeeded hanya dari ACK yang sah; failed/expired/cancelled berbeda |
| Contoh nyata | **Sirine Node 01 · Status perangkat: belum diketahui · Kendali belum tersedia** sampai jalur ACK teruji |

### 6.10 Native Provisioning and Recovery

| Atribut | Spesifikasi |
| --- | --- |
| Fungsi | Menemukan gateway, memberi konfigurasi jaringan yang didukung, dan membuktikan registrasi berhasil |
| Visual | Wizard `surface.canvas`, panel radius 8, Inter 16; ikon koneksi sky; tombol min 48 dan label langkah eksplisit |
| Default | Periksa capability terlebih dulu; native menampilkan metode tersedia; web memberi petunjuk metode yang benar-benar didukung |
| Hover / Active | Lanjut aktif setelah field valid; langkah jaringan menampilkan proses dan timeout; kembali mempertahankan draft yang aman |
| Disabled | BLE tidak didukung/izin ditolak tidak berubah menjadi tombol scan palsu; jelaskan izin yang diperlukan dan alternatif tersedia |
| Error / Alert | Gateway tak ditemukan, kredensial salah, dan server tak tercapai punya recovery berbeda; registrasi tidak sukses hanya karena WiFi tersambung |
| Contoh nyata | **Gateway belum terdaftar · Provisioning belum diimplementasikan**; metode AP tidak dijanjikan sebelum firmware mendukung |

## 7. Touch target dan ergonomi kontrol lapangan

1. Target minimum produk **48×48 CSS px pada web** dan **48×48 logical px/dp pada Flutter**, termasuk tombol hardware desktop. Ikon visual boleh 20–24 tetapi hitbox harus penuh dan tidak bertumpuk.
2. Jarak target umum minimal 8; tindakan ON/OFF berisiko berdekatan minimal 16. Tinggi tombol naik mengikuti pembesaran teks; min 48 bukan fixed 48.
3. WCAG 2.2 SC 2.5.8 level AA menetapkan minimum 24 CSS px dengan beberapa pengecualian. **48 adalah ketentuan produk TITEN yang lebih ketat**, bukan angka minimum WCAG tersebut. [W3C Target Size Minimum](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html).
4. Flutter juga menganjurkan target 48 serta pengujian screen reader dan skala teks besar. Produk tetap memakai 48 pada iOS agar kontrol hardware konsisten. [Flutter Accessibility](https://docs.flutter.dev/ui/accessibility).
5. Tindakan utama detail berada di area bawah yang mudah dijangkau satu tangan, dengan safe area. Tampilkan konteks target di dekat tombol; jangan memaksa pengguna mengingat node dari bagian atas halaman.
6. Jangan menaruh ON pada swipe row, marker peta, double tap, long press tersembunyi, atau hotkey satu karakter. Tap pertama membuka detail/konfirmasi; tap kedua mengirim aksi yang tertulis.
7. ON dan OFF harus memiliki label yang menyatakan aksi. Toggle visual mengikuti reported state perangkat; state requested/accepted bukan posisi ON yang terkonfirmasi.
8. Gesture swipe-to-dismiss hanya tambahan. Sediakan tombol Tutup/Batal yang setara; command yang sudah accepted tidak dianggap cancelled karena sheet ditutup.
9. Landscape tidak mengubah urutan risiko. Bila tinggi window pendek atau keyboard muncul, ubah footer sticky menjadi bagian scroll yang dapat dijangkau; jangan menutupi konfirmasi.
10. Pada tablet split view, hitung lebar window saat ini. Dua pane hanya jika masing-masing muat; pembesaran font dapat memaksa stack meski lebar masih tablet.

## 8. Aksesibilitas dan kepadatan yang dapat dipakai

### 8.1 Teks dan kontras

- Desktop: body 14–16; metadata 11–13 hanya untuk informasi nonkritis seperti schema/version. Target, level bahaya, waktu data terakhir, error, dan command memakai minimal 14.
- Mobile/tablet touch: body 16, metadata minimal 13, judul 18–24. Nilai telemetri 20–28 tetap punya label dan unit. Jangan memakai 11 untuk tanggal alert atau status keselamatan.
- Dukung text scaling hingga 200% tanpa clipping, tombol terpotong, label hilang, atau alert ter-ellipsis. Flutter menghormati scaling sistem; jangan memaksa text scale 1. [W3C Resize Text](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html).
- Gunakan tinggi otomatis, teks wrap, dan baris tambahan. ID sangat panjang dapat dipotong pada ringkasan jika ada akses eksplisit ke ID penuh; teks bahaya/perintah tidak boleh dipotong.
- Target produk mengikuti dokumen 01: **7:1 untuk seluruh teks aktif**, termasuk metadata dan teks besar. WCAG enhanced menetapkan 7:1 teks biasa dan 4,5:1 teks besar menurut definisinya; TITEN memilih target yang lebih ketat pada teks besar. [W3C Contrast Enhanced](https://www.w3.org/WAI/WCAG22/Understanding/contrast-enhanced.html).
- Batas/indikator komponen yang diperlukan untuk mengenali kontrol minimal 3:1 terhadap warna bersebelahan; fokus memakai indikator yang jelas. Border dekoratif kartu tidak otomatis harus 3:1. Audit setiap state dan tema. [W3C Non-text Contrast](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html).
- Memilih warna yang kontras tidak membuktikan produk memenuhi WCAG AAA secara menyeluruh. Kesimpulan kepatuhan memerlukan audit alur, konten, input, fokus, dan seluruh kriteria yang berlaku.
- Informasi semantik selalu memiliki teks/ikon/pola; warna rose sendiri tidak membedakan perangkat offline dan bahaya Awas.

### 8.2 Keyboard, screen reader, dan motion

- Semua jalur utama dapat dilakukan dengan Tab/Shift+Tab, Enter/Space, tombol panah pada komponen yang sesuai, dan Escape untuk menutup overlay yang aman.
- Urutan fokus: skip-link → navigasi → status halaman → filter → daftar/canvas alternatif → detail → tindakan. Jangan membuat fokus melompat ke chart setiap paket datang.
- Overlay modal menjebak fokus pada kontennya, memiliki nama, menonaktifkan background, dan mengembalikan fokus setelah ditutup; pane yang dipin bersifat nonmodal tanpa focus trap.
- Tombol memiliki nama spesifik seperti **Buka detail Node 01**, bukan **Klik di sini**. Status command mengumumkan target dan hasil; jangan membaca ulang seluruh telemetri setiap update.
- Banner perubahan penting memakai live region terkontrol. Bahaya baru yang kritis diumumkan sekali per kejadian; reconnect dan log rutin tidak memenuhi antrian pembaca layar.
- Peta/kanvas menyediakan daftar node setara; grafik menyediakan tabel nilai dan ringkasan tren/gap. Tooltip dapat dicapai keyboard serta touch.
- `prefers-reduced-motion` pada web dan pengaturan motion sistem pada native menghapus pulse, bounce, auto-pan, serta transisi perpindahan; status akhir tetap jelas dengan teks.
- Hormati high contrast/forced colors; border, focus ring, icon, dan pressed state tetap terlihat. Haptic/suara hanya tambahan, bukan satu-satunya tanda keberhasilan.
- Uji alur dengan TalkBack dan VoiceOver pada perangkat yang didukung. Dynamic Type dan Reduce Motion menjadi pertimbangan akses native. [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Apple Dynamic Type](https://developer.apple.com/videos/play/wwdc2024/10074/).
- Bahasa antarmuka baseline Bahasa Indonesia dengan label teknis yang diperlukan. RTL belum masuk scope; jangan mengklaim telah diuji RTL.

## 9. Rincian data padat, scroll, dan export

### 9.1 Prioritas kolom dan alternatif

| Prioritas | Daftar node | Log | Aturan layar sempit |
| --- | --- | --- | --- |
| P0 selalu terlihat | Node, bahaya, kesegaran, koneksi | Level, waktu/ketidaktersediaan waktu, node, pesan | Card berlabel; pesan boleh wrap |
| P1 pada ringkasan bila muat | Sensor valid terakhir, RSSI jika tersedia | Transport, command ID, event ID | Buka detail dengan satu tindakan |
| P2 detail | Firmware, pinmap, SNR, metadata registry | Raw payload, stack trace, schema, detail waktu UTC | Payload dapat disalin; tampilkan full value aksesibel |

- Mengubah tabel ke card tidak menghapus field atau fungsi: P1/P2 berpindah ke detail. Tampilkan count/filter/sort yang aktif pada kedua representasi.
- Tabel memakai header dan relasi sel yang semantik. Virtualisasi tidak boleh menghilangkan label, total hasil, keyboard navigation, atau kemampuan membaca hasil terpilih.
- Grafik legend membungkus beberapa baris dengan target 48; tidak menyembunyikan seri aktif di hover-only. Series label menyertakan unit; jangan menjumlahkan nilai sensor berbeda unit.
- Data table grafik memuat waktu, node, nama sensor, nilai, unit, validity, dan source. Download CSV/JSON mengambil seluruh hasil filter yang diotorisasi, bukan hanya titik/row yang dirender.
- Log live memiliki Pause/Resume dan indikator log baru. Scroll pengguna tidak ditarik ke bawah; kembali ke live adalah aksi eksplisit.

### 9.2 Zona waktu dan hasil export

- UI menampilkan tanggal lokal **Asia/Jakarta (UTC+07:00)** dan menyimpan/mentransmisikan instant UTC. Timestamp hilang tetap **—**; waktu muat layar tidak menggantikan waktu paket.
- Filter tanggal lokal dikonversi ke interval UTC setengah terbuka `[start, end)`; hari akhir inklusif di UI berarti awal hari berikutnya sebagai batas eksklusif, tanpa rekayasa 23:59:59.
- Nama/metadata export mencantumkan source LIVE/DEMO/cache, zona waktu, filter, waktu pembuatan file, schema, serta jumlah record. Timestamp per record mempertahankan zona/offset eksplisit.
- Metadata waktu pembuatan export tidak membuktikan data baru. Nilai null/missing diekspor sebagai null atau kolom kosong yang didokumentasikan; tidak menjadi 0.
- JSON menjaga nilai mentah/unit/status; CSV memiliki header dan UTF-8. Sanitasi sel teks yang dapat menjadi formula spreadsheet. Raw log hanya diekspor bila role mengizinkan dan tanpa credential.
- Export gagal memberikan pesan dan retry. Mobile browser memakai kemampuan download/share yang tersedia; kegagalan browser tidak diberi toast **Berhasil diekspor**.

### 9.3 Scroll dan safe area

- Halaman memiliki satu scroll vertikal utama; daftar sliver native mengikuti scroll tersebut. Nested scroll hanya untuk panel beralasan seperti tabel payload, bukan setiap card.
- Web menghormati safe-area inset dan tinggi viewport dinamis; native menghindari notch/status bar/navigation gesture/keyboard. Keyboard tidak menutupi field error atau tombol Simpan.
- Sticky header/banner/filter harus berbagi offset yang dihitung dari tinggi aktual. Saat banner wrap atau text scale naik, tinggi offset ikut berubah; fokus tidak tertutup header.
- Sisakan padding bawah sebesar action bar + safe area. Header atau footer sticky menjadi nonsticky jika membuat area baca terlalu pendek, termasuk landscape.
- Pada 320 CSS px dan zoom 400% dari viewport 1280, konten utama tetap satu arah scroll. Peta, diagram, atau tabel yang memang memerlukan hubungan dua dimensi boleh scroll lokal, dengan alternatif daftar/tabel yang aksesibel. [W3C Reflow](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html).
- Chart atau raw payload tidak otomatis mendapat pengecualian reflow: sediakan versi wrap/tabel. Jika detail teknis memang perlu baris asli, scroll hanya pada region berlabel dan dapat difokuskan.
- Jangan memakai `overflow:hidden` global untuk menyamarkan overflow. Tombol, pesan error, dan konten alert harus tetap dapat dijangkau.

## 10. State command lintas ukuran dan koneksi

Alur minimum: konfirmasi pengguna → `requested` → `accepted` → `executing` → `succeeded/failed`. `requested/accepted` dapat menjadi `failed/expired` jika ditolak atau melewati expiry sebelum mulai dieksekusi. `cancelled` hanya benar bila pembatalan sebelum kirim atau backend/perangkat mengonfirmasi pembatalan pada tahap yang mendukungnya.

| State | Teks UI | Efek responsif dan interaksi |
| --- | --- | --- |
| requested | Mengirim perintah | Kunci pengiriman ganda; tampilkan ID/target pada sheet/detail |
| accepted | Diterima server | Tombol tidak berubah menjadi state perangkat ON; tampilkan menunggu eksekusi |
| executing | Menunggu hasil perangkat | Status tetap terlihat bila overlay ditutup; pindah orientasi tidak membuat command baru; lewat SLA tanpa hasil ditulis **Hasil belum diketahui**, bukan gagal/mati/expired otomatis |
| succeeded | Perangkat mengonfirmasi hasil | Tampilkan ACK yang cocok dengan command ID/target/action dan reported state; haptic sukses boleh digunakan |
| failed | Perintah gagal | Alasan dan recovery; retry menghasilkan command baru setelah konfirmasi baru |
| expired | Perintah kedaluwarsa sebelum dieksekusi | Hanya dari keputusan backend/perangkat yang sah; jangan replay saat reconnect; pisahkan dari kegagalan sensor |
| cancelled | Perintah dibatalkan | Tampilkan bukti/ruang lingkup pembatalan; menutup drawer saja tidak membatalkan perintah accepted |

Command harus memiliki ID idempotensi, target, aksi, expiry, actor, dan audit. Tidak ada antrean offline untuk command hardware. Cache command hanya dipakai untuk membaca riwayat/state; reconnect menyegarkan status lalu meminta aksi baru jika pengguna masih ingin mengirim. Succeeded berarti ACK sah menurut kontrak; tanpa sensor umpan balik fisik, label tidak boleh mengklaim bunyi sirine telah diukur.

## 11. Matriks QA wajib

Semua kasus berikut adalah rencana uji dengan status awal **Belum diuji**. Gunakan fixture terpisah berlabel DEMO untuk nilai sintetik; gunakan data fisik hanya setelah tersedia. Catat build, OS/browser, tema, skala, metode input, expected/actual, dan bukti screenshot atau rekaman.

| ID | Window / kondisi | Skenario | Kriteria lulus |
| --- | --- | --- | --- |
| R01 | 320×568 CSS px | Overview mobile web | Tidak ada scroll horizontal halaman; mode/bahaya/data kosong/Detail terbaca |
| R02 | 360×640 dan 390×844 | Android/iPhone browser | Target 48, safe area, sheet dan retry dapat dipakai satu tangan |
| R03 | 639×800 | Tepat sebelum batas | Mobile navigation; konten stack; semua field tersedia di detail |
| R04 | 640×800 | Batas bawah tablet | Tablet; rail/drawer valid; jangan memakai mobile karena `<=640` |
| R05 | 1024×768 | Batas atas tablet | Tetap tablet; dua pane hanya jika minimum pane dan scale muat |
| R06 | 1025×768 dan 1024,5×768 | Sesudah batas | Desktop; tidak ada celah rentang media query pecahan |
| R07 | 1280×720 dan 1440×900 | Desktop umum | Sidebar, table/log, drawer, dan fokus tidak bertumpuk |
| R08 | 1920×1080 dan 2560×1440 | Layar besar | Canvas dibatasi wajar; data tidak menjadi pulau kosong atau baris terlalu panjang |
| R09 | 800×600 →600×800 | Rotate/resize tablet | Node/filter/draft/scroll wajar bertahan; command tidak dikirim ulang |
| R10 | Split view 320/640/900 | Flutter tablet/window | Breakpoint berdasarkan constraint aktual; bukan nama tablet |
| R11 | 640×360 landscape | Detail + konfirmasi | Footer tidak menutupi target/error; tombol tetap dapat discroll |
| R12 | Semua breakpoint, teks 200% | Alert panjang + command | Tidak ada clipping/ellipsis informasi kritis; tinggi komponen berkembang |
| R13 | 1280 CSS px pada zoom 400% | Web reflow setara 320 | Scroll halaman satu arah; pengecualian 2D hanya region yang perlu dan berlabel |
| R14 | Keyboard saja | Menu →filter→node→command→close | Urutan logis, fokus terlihat, tidak terjebak di luar modal, return focus tepat |
| R15 | TalkBack / VoiceOver | Node unknown + failed command | Label node/field/state/hasil terbaca; tidak ada spam per paket |
| R16 | Dark/light + high contrast | Semua state komponen | Kontras diuji, status tidak hanya warna, focus ring terlihat |
| R17 | Reduced Motion aktif | Reconnect, chart, drawer | Tidak ada pulse/auto-pan/bounce; perubahan state tetap jelas |
| R18 | LIVE tanpa data | Cold boot dan backend belum ada | `—`, unknown dan penjelasan; tidak muncul angka fallback/AMAN/online palsu |
| R19 | DEMO | Simulasi + export + kontrol | Label DEMO pada hasil; tidak ada command ke perangkat nyata |
| R20 | OFFLINE dengan cache | Baca lalu coba ON | Umur/sumber cache jelas; ON disabled dengan alasan; tidak ada replay setelah online |
| R21 | stale/missing/planned_sleep | Jadwal laporan berubah | Threshold memakai R/J; planned sleep dikecualikan; missing tidak otomatis offline |
| R22 | Koneksi server hidup, gateway unknown | Overview dan detail | Server online tidak membuat gateway/node online |
| R23 | Chart history kosong/gap/error | Ubah periode dan tabel | Empty/gap/error berbeda; download tidak membuat pengukuran palsu |
| R24 | Log baru saat scroll atas | Pause/Resume/filter | Scroll tidak terseret; jumlah baru valid; detail payload bisa diakses |
| R25 | Filter tanggal lokal | Export batas awal/akhir | Konversi UTC tepat, metadata zona terlihat, seluruh hasil terotorisasi diekspor |
| R26 | Command accepted tanpa ACK | Tutup sheet, rotate, reconnect | Tidak tampil succeeded; tetap dapat ditelusuri berdasarkan ID; expiry ditangani |
| R27 | Command ACK cocok/tidak cocok | Hasil firmware/backend | Hanya ACK sah menghasilkan succeeded; mismatched ID/target diabaikan dan diaudit |
| R28 | BLE izin ditolak/tidak tersedia | Native pairing dan web | Recovery nyata; tidak ada scan palsu; AP hanya muncul jika didukung |
| R29 | Soft keyboard + safe area | Form config/provisioning | Field aktif, error, dan tombol aksi terlihat/dapat discroll; secret tidak tampil di log |
| R30 | Touch cepat/dobel + mouse | Tombol hardware/marker | Satu command per konfirmasi; hitbox tidak overlap; peta punya daftar setara |

## 12. Gerbang penerimaan implementasi

- [ ] Tiga breakpoint identik pada web/native; semua boundary dan resize di atas lulus.
- [ ] Komponen bagian 6.1–6.10 memiliki default, hover/active/focus, disabled, dan error yang dapat didemokan.
- [ ] LIVE, DEMO, OFFLINE/cache, kesegaran, dan bahaya tidak tertukar pada ukuran mana pun.
- [ ] Field hilang tidak diisi fallback sensor, lokasi, baterai, RSSI, atau timestamp fiktif.
- [ ] Semua kontrol hardware 48×48, konfirmasi eksplisit, akses sesuai role, serta hasil berbasis command/ACK.
- [ ] Native dan mobile web tetap memiliki jalur kerja yang utuh ketika hover, gesture, haptic, atau BLE tidak tersedia.
- [ ] Teks 200%, reflow 320/zoom 400%, keyboard, screen reader, reduced motion, tema, dan kontras sudah diuji dengan bukti.
- [ ] Chart/log memiliki alternatif aksesibel; filter/export menjaga unit, zona waktu, sumber, validitas, dan otorisasi.
- [ ] Spesifikasi yang belum didukung runtime diberi capability state jujur; tidak ada toast sukses untuk operasi yang belum dikerjakan.
- [ ] Hasil QA dicatat terpisah dari spesifikasi; kelulusan UI tidak dianggap bukti integrasi perangkat atau kelayakan peringatan operasional.
