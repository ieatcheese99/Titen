# Redesign Flutter TITEN — status 9 Oktober 2026

## Pilihan pengguna yang sudah diterima

- Light palette: canvas `#F8FAFC`, panel `#FFFFFF`, CTA `#0284C7` dengan teks `#FFFFFF`, teks utama `#0F172A`, teks muted `#64748B`, border kontrol `#94A3B8`, aksen telemetri `#0891B2`.
- Lokasi node memiliki peta 2D dan medan 3D geografis asli berdasarkan koordinat serta elevasi.
- Lokasi pemasangan belum ditentukan; pengaturan koordinat node perlu dibuat terlebih dahulu.
- Flutter harus responsif untuk mobile/PC serta app/web.

## Bagian yang sudah dikerjakan

- Token light dan kompatibilitas warna lama diperbarui; loader web dan warna tema PWA mengikuti palette.
- Ringkasan node/gateway, badge, metadata node dan header dapat membungkus pada layar sempit; menu header mobile mengelompokkan pencarian/pengaturan.
- Waktu di header berasal dari laporan node, bukan waktu render. Lokasi Live tidak lagi diberi nama demo.
- Peta 2D menolak koordinat invalid, fokus pada posisi node yang tersedia, dan menampilkan keadaan kosong ketika lokasi belum disetel; pusat Bandung yang hardcoded dihapus.
- UI mulai tanpa menunggu Firebase/notifikasi. Stream Live menunggu Firebase siap; kesalahan bootstrap ditampilkan melalui status data, tanpa fallback demo. Firebase memiliki batas tunggu 20 detik.
- `flutter analyze --no-pub` lolos; 16 test lolos termasuk layar 320/360/640/1440 dp pada text scale 1.3 dan isolasi Live/DEMO. Build web berhasil; dashboard desktop dan 360 px telah dibuka di browser.

## Pilihan yang masih menunggu pengguna

1. Login/register: Firebase Email/Password, Email/Password + Google, atau tampilan saja.
2. Arah visual: modern light+dark, modern light saja, atau gaya teknis yang diperbarui.
3. Sumber medan asli: AWS/Mapzen DEM terbuka atau Cesium World Terrain.

Pilihan-pilihan tersebut belum diambil otomatis. Pengaturan koordinat, renderer terrain, dan halaman autentikasi belum dibuat. Keberhasilan build web belum membuktikan build atau operasi perangkat Android/Windows native.

## Sumber terrain yang telah diperiksa

- [AWS/Mapzen Terrain Tiles](https://registry.opendata.aws/terrain-tiles/): dataset tinggi medan global yang tersedia publik tanpa akun AWS. GET Terrarium tile `0/0/0` pada endpoint path-style berhasil dengan CORS `*`; wilayah node belum ditetapkan dan belum diuji.
- [Format Terrarium](https://github.com/tilezen/joerd/blob/master/docs/formats.md): elevasi meter di-decode dengan `R × 256 + G + B / 256 − 32768`. Terrain harus memakai data ini, bukan bukit buatan; marker dapat ditempatkan pada tinggi DEM dengan label sumber yang jelas.
- [Attribution Tilezen](https://github.com/tilezen/joerd/blob/master/docs/attribution.md): kredit mengikuti sumber dataset elevasi.
- [Cesium World Terrain](https://cesium.com/platform/cesium-ion/content/cesium-world-terrain/): terrain global; membutuhkan setup akun/token serta integrasi renderer web/native.

Preview sementara: `ui/previews/flutter-light-desktop.jpg` dan `ui/previews/flutter-light-mobile.jpg`. Preview menunjukkan pembaruan palette dan layout dasar, bukan hasil akhir redesign.
