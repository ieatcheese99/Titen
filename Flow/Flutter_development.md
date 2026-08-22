# 🏔️🔥 TITEN Mobile App
### Sistem Peringatan Dini Tanah Longsor & Kebakaran Hutan — Aplikasi Flutter

> **TITEN** (Tim TRILOGY — SMK Budi Luhur, Kota Tangerang) adalah aplikasi mobile pendamping perangkat IoT edge (ESP32 + LoRa 915MHz + Sensor Fusion) untuk memantau dan memberi peringatan dini **dua bencana sekaligus**: tanah longsor dan kebakaran hutan/lahan (karhutla).
>
> Dokumen ini adalah **README teknis lengkap** untuk tim developer (dan AI assistant) yang mengerjakan aplikasi mobile. Simpan file ini di root repo Flutter agar AI (Claude/Copilot/dsb) punya konteks penuh saat ditanya apa pun soal proyek ini.

---

## 📌 Daftar Isi

1. [Ringkasan Proyek](#1-ringkasan-proyek)
2. [Keputusan Teknologi (Tech Stack)](#2-keputusan-teknologi-tech-stack)
3. [Arsitektur Sistem End-to-End](#3-arsitektur-sistem-end-to-end)
4. [Design System — Firmus Tactical Light](#4-design-system--firmus-tactical-light)
5. [Struktur Folder Proyek Flutter](#5-struktur-folder-proyek-flutter)
6. [Skema Data (Firestore)](#6-skema-data-firestore)
7. [State Management dengan Riverpod](#7-state-management-dengan-riverpod)
8. [Peta Sensor (flutter_map + OpenStreetMap)](#8-peta-sensor-flutter_map--openstreetmap)
9. [Push Notification (FCM)](#9-push-notification-fcm)
10. [Daftar Layar & Navigasi](#10-daftar-layar--navigasi)
11. [Keamanan: PIN Modal untuk Uji Sirine](#11-keamanan-pin-modal-untuk-uji-sirine)
12. [Setup & Instalasi](#12-setup--instalasi)
13. [Dependency (pubspec.yaml)](#13-dependency-pubspecyaml)
14. [Roadmap Pengembangan](#14-roadmap-pengembangan)
15. [FAQ untuk AI Assistant](#15-faq-untuk-ai-assistant)

---

## 1. Ringkasan Proyek

| Item | Detail |
|---|---|
| **Nama Produk** | TITEN — Sistem Peringatan Dini Tanah Longsor & Kebakaran Hutan |
| **Bagian yang dikerjakan** | Aplikasi Mobile (Flutter) — konsumen data dari Cloud/Firestore |
| **Kompetisi** | MAGE 12 — Subtema *Climate Disaster Technology* |
| **Tim** | TRILOGY — Muhammad Zahir Siraj, Zabdan Harjati Purnomo, Muhammad Rasya Al Faridzi |
| **Institusi** | SMK Budi Luhur, Kota Tangerang |
| **Target Pengguna** | Warga desa rawan bencana, Operator BPBD/SAR, Teknisi lapangan IoT |
| **Platform** | Android & iOS (Flutter, mobile-first, responsive) |

Aplikasi ini **tidak** berkomunikasi langsung dengan sensor node. Alurnya:

```
Sensor Node (ESP32+LoRa) → Gateway (ESP32+WiFi) → Cloud (Consensus Engine + Firestore) → App Flutter (baca real-time + terima FCM)
```

Fungsi utama aplikasi:
- Menampilkan status keseluruhan zona (Aman/Waspada/Siaga/Awas) secara real-time.
- Menampilkan peta sebaran node sensor beserta status masing-masing.
- Menampilkan telemetri detail per node (kemiringan tanah, kelembapan tanah, suhu udara, kelembapan udara, baterai, sinyal LoRa).
- Menerima **push notification** instan saat status **AWAS** (Longsor/Karhutla) tervalidasi oleh Multi-Node Consensus Engine.
- Menyediakan menu uji sirine jarak jauh (khusus teknisi, dengan proteksi PIN).
- Menampilkan grafik historis (tren 7 hari) untuk pengambilan keputusan siaga bencana.

---

## 2. Keputusan Teknologi (Tech Stack)

Berdasarkan diskusi awal proyek, berikut stack yang **disepakati**:

| Komponen | Pilihan | Alasan |
|---|---|---|
| **Framework** | Flutter (Dart, null-safety) | Cross-platform, sesuai PRD v2.1.0 |
| **Backend/Database** | 🔥 **Firebase** — Cloud Firestore + Firebase Cloud Messaging (FCM) | Realtime out-of-the-box, push notification native terintegrasi, cocok untuk tim kecil/kompetisi, gateway bisa langsung tulis via REST/Admin SDK tanpa server terpisah |
| **State Management** | 🧩 **Riverpod** (`flutter_riverpod` + `riverpod_generator`) | Type-safe, testable, tidak perlu `BuildContext` untuk akses provider, lebih ringan dari Bloc untuk tim kecil, lebih scalable dari Provider biasa |
| **Peta** | 🗺️ **OpenStreetMap via `flutter_map`** | **Direkomendasikan** karena: gratis tanpa API key/billing (cocok untuk kompetisi & anggaran terbatas), cukup untuk menampilkan marker node + status warna, ringan untuk mobile. *(Bisa upgrade ke Google Maps/Mapbox nanti jika butuh Street View/traffic layer — tinggal ganti widget map, struktur data lokasi tidak berubah)* |
| **Grafik** | `fl_chart` | Untuk grafik tren suhu/kelembapan 7 hari (Analytics screen) |
| **Local Notification** | `flutter_local_notifications` | Menampilkan alert saat app di foreground |
| **Networking Gateway → Cloud** | MQTT (opsional, via broker) atau HTTP REST → Cloud Function → Firestore | Sesuai arsitektur PRD Layer 2 |

> ℹ️ **Catatan untuk AI**: Jika user meminta ubah backend ke Supabase/REST custom atau ganti map ke Google Maps, sesuaikan bagian §6 (skema data) dan §8 (peta) — sisanya (UI, state, navigasi) tidak perlu berubah signifikan karena sudah dipisah lewat Riverpod repository pattern.

---

## 3. Arsitektur Sistem End-to-End

```
┌─────────────────────┐     LoRa 915MHz      ┌──────────────────────┐
│  EDGE SENSOR NODE    │ ───────────────────► │   LoRa GATEWAY NODE  │
│  ESP32 + SX1276      │   16-byte payload     │  ESP32 + SX1276+WiFi │
│  MPU6050 / Soil /    │   (TitenPayload)      │  Forward via HTTP/   │
│  DHT22 / SoPoWake    │                       │  MQTT                │
└─────────────────────┘                       └──────────┬───────────┘
                                                            │
                                                            ▼
                                          ┌───────────────────────────────┐
                                          │  CLOUD & CONSENSUS ENGINE     │
                                          │  - Validasi 2-dari-3 node     │
                                          │  - Cloud Function (Node/TS)   │
                                          │  - Tulis ke Firestore         │
                                          │  - Trigger FCM saat AWAS      │
                                          └───────────────┬───────────────┘
                                                            │
                                     ┌──────────────────────┴──────────────────────┐
                                     ▼                                              ▼
                     ┌───────────────────────────┐                 ┌───────────────────────────┐
                     │   FLUTTER MOBILE APP      │                 │   FIREBASE CLOUD           │
                     │   - Riverpod state        │◄───realtime─────│   MESSAGING (FCM)          │
                     │   - Firestore stream       │                │   - High-priority alert     │
                     │   - flutter_map (OSM)      │                │   - Deep link ke detail node│
                     │   - fl_chart analytics     │                └───────────────────────────┘
                     └───────────────────────────┘
```

**Peran aplikasi Flutter dalam arsitektur ini murni sebagai *presentation layer*** — semua logika validasi bencana (Dual Hazard Evaluation & Multi-Node Consensus) terjadi di Edge (ESP32) dan Cloud, bukan di app.

---

## 4. Design System — Firmus Tactical Light

Diambil dari referensi desain (screenshot dashboard) dan spesifikasi PRD §9. Tema ini **wajib dipakai konsisten** di seluruh layar Flutter.

### 4.1 Palet Warna Dasar

| Token | Hex | Kegunaan |
|---|---|---|
| `surfaceWhite` | `#FFFFFF` | Kartu, app bar, bottom nav |
| `baseBackground` | `#F8FAFC` | Background utama layar |
| `outlineBorder` | `#E2E8F0` | Border tipis antar kartu/section |
| `textMain` | `#0F172A` | Teks judul & isi utama |
| `textMuted` | `#64748B` | Label sekunder (mis. "LAST UPDATED") |
| `primaryAccent` | `#059669` (emerald deep) | Sidebar/nav item aktif, tombol utama (sesuai referensi UI: hijau pada nav "Dashboard" aktif) |

### 4.2 Warna Status Bencana (Sangat Penting — Jangan Diubah Urutannya)

| Status | Hex | Makna |
|---|---|---|
| 🟢 **Aman** | `#10B981` (Emerald) | Semua parameter normal |
| 🟡 **Waspada** | `#F59E0B` (Amber) | Anomali ringan terdeteksi, belum tervalidasi |
| 🟠 **Siaga** | `#F97316` (Orange) | Anomali kuat, menunggu konsensus node lain |
| 🔴 **Awas Longsor** | `#EF4444` (Crimson) | Tervalidasi ≥2 node: kemiringan >5.0° & kelembapan tanah >80% |
| 🟠🔥 **Awas Karhutla** | `#EA580C` (Flame Orange) | Tervalidasi ≥2 node: suhu udara >45°C & kelembapan udara <25% |

### 4.3 Flutter ThemeData (siap pakai)

```dart
import 'package:flutter/material.dart';

class TitenColors {
  static const surfaceWhite = Color(0xFFFFFFFF);
  static const baseBackground = Color(0xFFF8FAFC);
  static const outlineBorder = Color(0xFFE2E8F0);
  static const textMain = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const primaryAccent = Color(0xFF059669);

  static const statusAman = Color(0xFF10B981);
  static const statusWaspada = Color(0xFFF59E0B);
  static const statusSiaga = Color(0xFFF97316);
  static const statusAwasLongsor = Color(0xFFEF4444);
  static const statusAwasKarhutla = Color(0xFFEA580C);
}

ThemeData titenLightTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: TitenColors.baseBackground,
    colorScheme: ColorScheme.light(
      primary: TitenColors.primaryAccent,
      surface: TitenColors.surfaceWhite,
      outline: TitenColors.outlineBorder,
    ),
    fontFamily: 'Inter', // fallback: system default
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: TitenColors.textMain, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: TitenColors.textMain),
      bodySmall: TextStyle(color: TitenColors.textMuted),
    ),
    cardTheme: CardThemeData(
      color: TitenColors.surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TitenColors.outlineBorder),
      ),
    ),
  );
}

/// Helper: ambil warna dari status_level + hazard_type (lihat §6.2)
Color statusColor(int statusLevel, int hazardType) {
  switch (statusLevel) {
    case 0: return TitenColors.statusAman;
    case 1: return TitenColors.statusWaspada;
    case 2: return TitenColors.statusSiaga;
    case 3: return hazardType == 2
        ? TitenColors.statusAwasKarhutla
        : TitenColors.statusAwasLongsor;
    default: return TitenColors.textMuted;
  }
}
```

### 4.4 Prinsip Layout (dari referensi screenshot)

- **Bento grid card** untuk ringkasan sensor (mis. "Soil Moisture 42.8%", "Avg Temperature 24.5°C") — rounded corner besar (16px), tanpa shadow berat, border tipis abu-abu.
- **Banner status** di atas dashboard: full-width, border kiri tebal berwarna status, ikon bulat, teks tebal ("ALL ZONES SAFE") + deskripsi singkat + timestamp kanan.
- **Search bar pill-shape** di app bar untuk cari lokasi/sensor.
- Ikon **notification bell** + **avatar** di kanan atas app bar.
- Peta ditampilkan dalam card terpisah dengan tombol "Filters" & "Layers" di kanan atas card.

---

## 5. Struktur Folder Proyek Flutter

Menggunakan pendekatan **feature-first**, agar setiap fitur (dashboard, peta, sensor detail, emergency, settings) berdiri sendiri dan mudah dipelihara/di-generate ulang oleh AI.

```
lib/
├── main.dart
├── app.dart                         # MaterialApp + router + theme
├── core/
│   ├── theme/
│   │   └── titen_theme.dart         # Lihat §4.3
│   ├── constants/
│   │   └── hazard_constants.dart    # Threshold FR-1.4 (tilt>5.0°, soil>80%, dst)
│   ├── router/
│   │   └── app_router.dart          # go_router config
│   └── widgets/
│       ├── status_banner.dart
│       ├── bento_card.dart
│       └── pin_modal.dart           # Lihat §11
├── features/
│   ├── dashboard/
│   │   ├── data/
│   │   ├── application/             # Riverpod providers/notifiers
│   │   └── presentation/
│   │       └── dashboard_screen.dart
│   ├── sensor_map/
│   │   ├── application/
│   │   └── presentation/
│   │       └── sensor_map_screen.dart
│   ├── analytics/
│   │   └── presentation/
│   │       └── analytics_screen.dart
│   ├── sensors/                     # daftar & detail per node
│   │   └── presentation/
│   │       ├── sensor_list_screen.dart
│   │       └── sensor_detail_screen.dart
│   ├── emergency/                   # riwayat alert + uji sirine
│   │   └── presentation/
│   │       └── emergency_screen.dart
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart
└── services/
    ├── firestore_service.dart
    ├── fcm_service.dart
    └── auth_service.dart            # role: warga / bpbd / teknisi
```

---

## 6. Skema Data (Firestore)

Diturunkan langsung dari struct biner `TitenPayload` (PRD §7) yang dikirim dari Edge Node via LoRa, lalu diteruskan Gateway → Cloud Function → Firestore.

### 6.1 Collection: `nodes`

```
nodes/{nodeId}
├── node_id: number         // 1-255
├── name: string            // "Sensor Node 04 - Tebing Selatan"
├── location: GeoPoint
├── node_type: string       // "landslide" | "karhutla" | "combo"
├── last_status_level: number   // 0-3, lihat §6.2
├── last_hazard_type: number    // 0: Normal, 1: Longsor, 2: Karhutla
├── battery_pct: number
├── lora_rssi: number
├── lora_snr: number
└── last_seen: Timestamp
```

### 6.2 Sub-collection: `nodes/{nodeId}/telemetry`

Cerminan 1:1 dari `TitenPayload` (16 byte) di firmware:

```
telemetry/{autoId}
├── node_id: number
├── battery_pct: number       // 0-100
├── tilt_deg: number          // tilt_x10 / 10
├── soil_moisture_pct: number // 0-100
├── air_temp_c: number        // air_temp_x10 / 10
├── air_humidity_pct: number  // 0-100
├── hazard_type: number       // 0: Normal, 1: Longsor, 2: Karhutla
├── status_level: number      // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
└── timestamp: Timestamp      // dari timestamp_rtc
```

> ⚠️ **Threshold acuan (FR-1.4)** — dipakai untuk badge peringatan di UI (bukan untuk re-validasi, karena validasi final ada di Consensus Engine):
> - Longsor: `tilt_deg > 5.0` **DAN** `soil_moisture_pct > 80`
> - Karhutla: `air_temp_c > 45.0` **DAN** `air_humidity_pct < 25`

### 6.3 Collection: `alerts` (hasil Multi-Node Consensus)

```
alerts/{alertId}
├── hazard_type: number        // 1: Longsor, 2: Karhutla
├── status_level: number       // biasanya 3 (Awas)
├── node_ids: array<number>    // node yang setuju, min. 2 dari 3
├── confirmed_at: Timestamp
├── location: GeoPoint         // centroid dari node yang terlibat
├── resolved: boolean
└── resolved_at: Timestamp?
```

### 6.4 Collection: `users`

```
users/{uid}
├── name: string
├── role: string      // "warga" | "bpbd" | "teknisi"
├── fcm_token: string
└── phone: string?
```

---

## 7. State Management dengan Riverpod

Pola yang dipakai: **AsyncNotifierProvider** untuk stream Firestore + **Repository pattern** agar sumber data mudah diganti (mis. jika nanti pindah dari Firestore ke REST API custom, cukup ubah repository, provider & UI tidak berubah).

```dart
// features/dashboard/data/node_repository.dart
abstract class NodeRepository {
  Stream<List<SensorNode>> watchAllNodes();
}

class FirestoreNodeRepository implements NodeRepository {
  final _col = FirebaseFirestore.instance.collection('nodes');

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    return _col.snapshots().map(
      (snap) => snap.docs.map((d) => SensorNode.fromMap(d.data(), d.id)).toList(),
    );
  }
}

final nodeRepositoryProvider = Provider<NodeRepository>((ref) {
  return FirestoreNodeRepository();
});

// features/dashboard/application/dashboard_controller.dart
final allNodesProvider = StreamProvider<List<SensorNode>>((ref) {
  return ref.watch(nodeRepositoryProvider).watchAllNodes();
});

/// Turunan: status zona keseluruhan (untuk banner "ALL ZONES SAFE")
final overallZoneStatusProvider = Provider<ZoneStatus>((ref) {
  final nodesAsync = ref.watch(allNodesProvider);
  return nodesAsync.when(
    data: (nodes) {
      final worst = nodes.fold<int>(0, (max, n) => n.statusLevel > max ? n.statusLevel : max);
      return ZoneStatus.fromLevel(worst);
    },
    loading: () => ZoneStatus.loading,
    error: (_, __) => ZoneStatus.unknown,
  );
});
```

Gunakan `ConsumerWidget`/`HookConsumerWidget` di layer presentation, jangan pernah panggil Firestore langsung dari widget.

---

## 8. Peta Sensor (flutter_map + OpenStreetMap)

Rekomendasi: **`flutter_map`** dengan tile OpenStreetMap standar (gratis, tanpa API key, cukup untuk kebutuhan menampilkan marker berwarna sesuai status node).

```dart
FlutterMap(
  options: MapOptions(
    initialCenter: LatLng(-6.9147, 107.6098), // contoh: area rawan
    initialZoom: 13,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.trilogy.titen',
    ),
    MarkerLayer(
      markers: nodes.map((n) => Marker(
        point: LatLng(n.location.latitude, n.location.longitude),
        width: 40, height: 40,
        child: Icon(Icons.location_on,
          color: statusColor(n.statusLevel, n.hazardType), size: 36),
      )).toList(),
    ),
  ],
)
```

> 💡 Karena node berada di area terpencil (hutan/tebing) yang mungkin tidak selalu online, tampilkan indikator "last seen" di setiap marker (tap → bottom sheet detail node).
> 💡 Jika ke depan butuh basemap topografi (kontur ketinggian, penting untuk visualisasi lereng longsor), pertimbangkan tile provider seperti OpenTopoMap — tinggal ganti `urlTemplate`.

---

## 9. Push Notification (FCM)

### 9.1 Alur

1. Cloud Function memvalidasi konsensus (≥2 dari 3 node) → menulis dokumen ke `alerts/`.
2. Cloud Function trigger `onCreate` di `alerts/{alertId}` → kirim FCM ke topic sesuai role (`role_bpbd`, `role_warga_<nodeArea>`) atau ke token individual di `users`.
3. Payload FCM:

```json
{
  "notification": {
    "title": "🔴 AWAS LONGSOR — Node 04",
    "body": "Kemiringan 7.2° & kelembapan tanah 86%. Tervalidasi 2/3 node."
  },
  "data": {
    "alert_id": "abc123",
    "hazard_type": "1",
    "node_id": "4",
    "screen": "emergency_detail"
  },
  "android": { "priority": "high" },
  "apns": { "headers": { "apns-priority": "10" } }
}
```

### 9.2 Setup di Flutter

```dart
// services/fcm_service.dart
class FcmService {
  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNavigation);
  }

  void _handleNavigation(RemoteMessage msg) {
    final screen = msg.data['screen'];
    if (screen == 'emergency_detail') {
      // router.push('/emergency/${msg.data['alert_id']}')
    }
  }
}
```

Gunakan `flutter_local_notifications` untuk menampilkan alert saat app di foreground (FCM tidak otomatis menampilkan notifikasi saat app aktif di Android).

---

## 10. Daftar Layar & Navigasi

Bottom Navigation Bar (mengikuti sidebar pada referensi desain, diadaptasi ke mobile):

| Ikon | Layar | Isi Utama |
|---|---|---|
| 🏠 | **Dashboard** | Status banner zona, bento grid telemetri ringkas, mini map |
| 📊 | **Analytics** | Grafik tren 7 hari (suhu, kelembapan tanah, kemiringan) via `fl_chart` |
| 📡 | **Sensors** | Daftar semua node + status, tap → detail node (baterai, RSSI/SNR, riwayat) |
| 🚨 | **Emergency** | Riwayat alert (AWAS), tombol uji sirine (PIN-protected), status resolved/aktif |
| ⚙️ | **Settings** | Profil, role user, notifikasi, tentang aplikasi |

### Detail Dashboard Screen (sesuai referensi screenshot)

- App bar: search bar + bell icon (badge merah jika ada alert baru) + avatar.
- Status banner full-width (hijau/kuning/oranye/merah sesuai §4.2).
- Card "Sensor Network Map" (preview map, tap → full screen Sensors Map).
- Bento cards di sisi kanan (di mobile: di bawah map, stacked vertical): Soil Moisture, Avg Temperature, dan bisa ditambah Tilt Angle & Air Humidity.

---

## 11. Keamanan: PIN Modal untuk Uji Sirine

Sesuai **US-05**: teknisi lapangan perlu menguji sirine tanpa memicu kepanikan warga → wajib PIN 4-digit sebelum command "test siren" dikirim.

```dart
// core/widgets/pin_modal.dart
Future<bool> showPinModal(BuildContext context) async {
  final controller = TextEditingController();
  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Verifikasi Teknisi'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 4,
        obscureText: true,
        decoration: const InputDecoration(hintText: 'Masukkan PIN 4 digit'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text == expectedPin()),
          child: const Text('Konfirmasi'),
        ),
      ],
    ),
  ) ?? false;
}
```

> 🔒 PIN sebaiknya divalidasi ulang di **server-side** (Cloud Function), bukan hanya di client, agar tidak bisa dibypass lewat reverse-engineering APK.

---

## 12. Setup & Instalasi

```bash
# 1. Buat project
flutter create titen_app
cd titen_app

# 2. Konfigurasi Firebase
flutterfire configure   # pilih project Firebase, generate firebase_options.dart

# 3. Install dependencies
flutter pub get

# 4. Jalankan
flutter run
```

Prasyarat:
- Flutter SDK ≥ 3.19 (Dart ≥ 3.3, agar kompatibel dengan Riverpod generator terbaru)
- Akun Firebase + project sudah dibuat, Firestore & FCM diaktifkan
- Android Studio / Xcode untuk emulator

---

## 13. Dependency (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  firebase_core: ^3.1.0
  cloud_firestore: ^5.0.1
  firebase_messaging: ^15.0.1
  flutter_local_notifications: ^17.2.1
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  fl_chart: ^0.68.0
  go_router: ^14.2.0
  intl: ^0.19.0

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^4.0.0
```

---

## 14. Roadmap Pengembangan

- [ ] **Sprint 1**: Setup project, Firebase init, theme, navigasi dasar (bottom nav 5 layar kosong)
- [ ] **Sprint 2**: Dashboard screen — status banner + bento cards (data dummy dulu)
- [ ] **Sprint 3**: Integrasi Firestore real (`allNodesProvider`), tampilkan data live
- [ ] **Sprint 4**: Sensor Map screen dengan `flutter_map` + marker berwarna status
- [ ] **Sprint 5**: FCM integration + local notification + deep link ke Emergency screen
- [ ] **Sprint 6**: Analytics screen dengan `fl_chart` (tren 7 hari)
- [ ] **Sprint 7**: Emergency screen (riwayat alert + PIN modal uji sirine)
- [ ] **Sprint 8**: Polish UI sesuai referensi desain, testing di device fisik, siapkan demo untuk MAGE 12

---

## 15. FAQ untuk AI Assistant

> Bagian ini membantu AI (Claude/Copilot/dsb) menjawab pertanyaan lanjutan tanpa perlu bertanya ulang ke user.

**Q: Kenapa pakai Firestore, bukan realtime database biasa?**
A: Firestore lebih fleksibel untuk query bertingkat (nodes → telemetry sub-collection) dan terintegrasi native dengan FCM serta Cloud Functions untuk trigger konsensus.

**Q: Kenapa OpenStreetMap, bukan Google Maps?**
A: Tidak butuh API key/billing, cukup untuk kebutuhan marker status sensor, dan cocok untuk proyek kompetisi dengan budget terbatas. Bisa diganti ke Google Maps/Mapbox nanti tanpa mengubah struktur data lokasi (`GeoPoint` tetap sama).

**Q: Apakah aplikasi ini yang melakukan validasi Dual Hazard / Consensus?**
A: **Tidak.** Validasi Dual Hazard (tilt/soil untuk longsor, suhu/kelembapan untuk karhutla) dilakukan di firmware ESP32 (Edge). Validasi Multi-Node Consensus (2 dari 3 node setuju) dilakukan di Cloud Function. Aplikasi Flutter murni menampilkan hasil akhir secara real-time.

**Q: Bagaimana kalau user minta ganti state management ke Bloc?**
A: Ganti layer `application/` (Notifier → Cubit/Bloc), tapi struktur folder feature-first dan `Repository` pattern di layer `data/` tetap dipakai — tidak perlu redesain arsitektur.

**Q: Bagaimana kalau user minta tambah role/login?**
A: Tambahkan Firebase Auth, simpan `role` di collection `users`, lalu buat provider `currentUserRoleProvider` yang dipakai untuk guard fitur (mis. hanya `teknisi` yang bisa akses tombol uji sirine di §11).

**Q: Warna status disebut apa saja urutannya?**
A: Aman (`#10B981`) → Waspada (`#F59E0B`) → Siaga (`#F97316`) → Awas Longsor (`#EF4444`) / Awas Karhutla (`#EA580C`). Selalu urut dari level 0-3, lihat §4.2 dan §6.2.

**Q: File struct 16-byte `TitenPayload` diproses di mana?**
A: Di-decode oleh Gateway/Cloud Function menjadi JSON, baru ditulis ke Firestore sesuai skema §6.2. Aplikasi Flutter tidak pernah membaca binary payload secara langsung.

---

*Dokumen ini disusun berdasarkan PRD v2.1.0 (Mobile App Push Notification Spec) dan referensi desain "Firmus Tactical Light". Update dokumen ini setiap kali ada perubahan keputusan arsitektur agar tetap menjadi single source of truth bagi tim & AI assistant.*