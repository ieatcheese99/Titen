# Dokumentasi Flowchart & Activity Diagram System - TITEN EWS

> **Versi Dokumen**: v2.1.0  
> **Target Sistem**: TITEN IoT Early Warning System (Landslide & Forest Fire Dual Detection, SoPoWake Deep Sleep, LoRa 915MHz, Multi-Node Consensus, Flutter Light Mobile UX & FCM Push Notifications)  
> **Format File XML Draw.io**: Tersedia di direktori `c:\laragon\www\Titen\Flow\xml\`

---

## Ringkasan Direktori File Draw.io XML

Semua diagram dalam dokumen ini telah dibuat dalam format **Draw.io XML (`.drawio`)** siap pakai yang dapat langsung di-import atau dibuka melalui [Draw.io / Diagrams.net](https://app.diagrams.net).

| No | Nama Kategori | File Flowchart & Activity Diagram XML |
| :--- | :--- | :--- |
| **01** | **Edge Dual Sensing & SoPoWake Power Management** | [01_edge_sensing_sopowake.drawio.xml](file:///c:/laragon/www/Titen/Flow/xml/01_edge_sensing_sopowake.drawio.xml) |
| **02** | **Transmisi LoRa & Offline Data Buffering** | [02_lora_transmission_buffering.drawio.xml](file:///c:/laragon/www/Titen/Flow/xml/02_lora_transmission_buffering.drawio.xml) |
| **03** | **Cloud Backend & Dual Hazard Multi-Node Consensus Engine** | [03_cloud_consensus_engine.drawio.xml](file:///c:/laragon/www/Titen/Flow/xml/03_cloud_consensus_engine.drawio.xml) |
| **04** | **Peringatan Hierarkis, Sirine Lokal & Push Notifikasi Mobile** | [04_hierarchical_alert_mobile_siren.drawio.xml](file:///c:/laragon/www/Titen/Flow/xml/04_hierarchical_alert_mobile_siren.drawio.xml) |
| **05** | **Antarmuka Mobile Light Mode Flutter UX & Interaksi** | [05_gotham_friendly_ui_interaction.drawio.xml](file:///c:/laragon/www/Titen/Flow/xml/05_gotham_friendly_ui_interaction.drawio.xml) |

---

## Kategori 1: Edge Dual Sensing (Longsor & Karhutla) & SoPoWake

### 1.1 Deskripsi Alur & Logika Keputusan Dual Bencana
ESP32 menggunakan mode *Deep Sleep* (< 15µA) dan terbangun oleh 3 pemicu hardware:
1. **Interrupt Motion MPU6050 (GPIO 33)**: Akselerasi $> 0.15\,\text{g}$ atau perubahan sudut $\Delta\theta > 2.0^\circ$.
2. **Interrupt Heat/DHT22 (GPIO 27)**: Lonjakan suhu udara $> 45.0^\circ\text{C}$ atau kelembapan udara drop $< 25\%$.
3. **Timer RTC Internal**: Laporan rutin heartbeat setiap 6 jam sekali.

Saat terbangun, ESP32 membaca MPU6050 (Kemiringan), Capacitive Soil Probe (Kelembapan Tanah), dan DHT22 (Suhu & Kelembapan Udara), lalu mengevaluasi *Dual Hazard Decision*:
- **Cabang Longsor**: JIKA $\Delta\theta > 5.0^\circ$ DAN Kelembapan Tanah $> 80\% \longrightarrow$ `BAHAYA LONGSOR`.
- **Cabang Karhutla**: JIKA Suhu Udara $> 45.0^\circ\text{C}$ DAN Kelembapan Udara $< 25\% \longrightarrow$ `BAHAYA KARHUTLA`.
- **Normal**: JIKA semua sensor di bawah threshold $\longrightarrow$ Status `AMAN`.

### 1.2 Flowchart Edge Dual Sensing & SoPoWake
```mermaid
flowchart TD
    A[Start / Power On Node ESP32] --> B[Inisialisasi GPIO, I2C MPU6050, DHT22, SPI LoRa, ADC Soil, & INT]
    B --> C{Cek Voltage Baterai BMS\nGPIO 36 V_bat < 3.2V?}
    C -- YA --> D[Deep Discharge Protection\nDisable LoRa & Siren, Sleep ULP]
    C -- TIDAK --> E[Konfigurasi Interrupt SoPoWake\nMPU6050 INT, DHT22 Heat INT, RTC Timer 6-Jam]
    E --> F[Masuk ESP32 Deep Sleep < 15uA]
    F -- Interrupt Terpicu --> G[Pemicuan Wakeup Event\nMPU6050 / DHT22 / RTC Timer]
    G --> H[Sampling Multi-Sensor Fusion\n1. MPU6050: ΔPitch/ΔRoll\n2. Soil Moisture %\n3. DHT22: Air Temp °C & Humidity %]
    H --> I{Evaluasi Dual Hazard Decision}
    I -- Temp > 45C & Humid < 25% --> J[STATE BAHAYA KARHUTLA!\n1. Relay Sirine 120dB GPIO 26 HIGH\n2. LoRa Emergency Broadcast Karhutla]
    I -- Tilt > 5.0 deg & Soil > 80% --> K[STATE BAHAYA LONGSOR!\n1. Relay Sirine 120dB GPIO 26 HIGH\n2. LoRa Emergency Broadcast Longsor]
    I -- Sensor Normal --> L[Status AMAN\nKemas Payload Heartbeat -> Return Sleep]
    J --> F
    K --> F
    L --> F
```

---

## Kategori 2: Transmisi LoRa Dual Bencana & Offline Buffering

```mermaid
flowchart TD
    A[Start: Payload Telemetri Titen Payload 16-Byte] --> B[Encapsulate Payload with Hazard Type Bitmask]
    B --> C[Enkripsi Payload Simetris AES-128 Bit]
    C --> D[Kirim Paket RF LoRa 915MHz via SX1276]
    D --> E[Tunggu Balasan ACK Gateway Timeout 1.5 Detik]
    E --> F{Apakah ACK Diterima?}
    F -- TIDAK / Timeout --> G[Gateway Offline!\nTulis Struct 16-Byte ke SPIFFS Flash Ring Buffer Max 500 Log]
    F -- YA / Valid --> H[Data Diterima IoT Gateway -> Publish MQTT ke Cloud]
    G --> I[Return Deep Sleep]
    H --> I
```

---

## Kategori 3: Cloud Backend & Dual Hazard Multi-Node Consensus Engine

```mermaid
flowchart TD
    A[Start: Stream Data Telemetri MQTT dari Gateway] --> B[Simpan Telemetri ke Database PostgreSQL]
    B --> C{Apakah Node A Melaporkan Anomali Longsor / Karhutla?}
    C -- TIDAK --> D[Status Lereng & Hutan AMAN -> Update UI Emerald Green]
    C -- YA --> E[Trigger Multi-Node Consensus Engine\nQuery Node B & C dalam Radius 100m Window 10s]
    E --> F{Apakah >= 2 Node Mendeteksi Anomali Bencana Sesuai?}
    F -- TIDAK / < 2 Nodes --> G[KONSENSUS GAGAL: Anomali Lokal / Noise\nSirine Lokal TIDAK Berbunyi -> Silent Log]
    F -- YA / >= 2 Nodes --> H[KONSENSUS TERVERIFIKASI REAL BENCANA!\nStatus System: AWAS LONGSOR / AWAS KARHUTLA]
    H --> I[Dispatch Alert Hierarkis:\n1. Sirine 120dB & LED Strobe Local\n2. Push Notifikasi Aplikasi Mobile to BPBD Operator]
```

---

## Kategori 4: Peringatan Hierarkis & Remote Override via Push Notifikasi Mobile

```mermaid
flowchart TD
    A[Start: Peringatan Bencana Tervalidasi] --> B{Evaluasi Tipe Bencana}
    B -- Bahaya Longsor --> C[Format Push Alert: ⚠️ BAHAYA LONGSOR TERDETEKSI!]
    B -- Bahaya Karhutla --> D[Format Push Alert: 🔥 BAHAYA KEBAKARAN HUTAN TERDETEKSI!]
    C --> E[Attach Maps Link, Telemetry Data, & Action Buttons]
    D --> E
    E --> F[Send Push Notification to Mobile Application < 3s]
    F --> G{Operator BPBD Action}
    G -- Klik Matikan Sirine --> H[Kirim Downlink LoRa SIREN_OFF -> Relay LOW]
    G -- Klik Evakuasi --> I[Broadcast Push Notifikasi Evakuasi Warga]
```

---

## Kategori 5: Antarmuka Mobile Light Mode Flutter UX

```mermaid
flowchart TD
    A[Start: User membuka Aplikasi Mobile] --> B[Render Light Mode Palette #F8FAFC & #FFFFFF]
    B --> C[Render Mobile Viewport Frame & Top Bar]
    C --> D[Active Bottom Navigation Bar: Status | Peta | Logs | Alerts]
    D --> E[Simulasi Dual Hazard Bar: Aman | Waspada Longsor | Waspada Karhutla | Siaga | AWAS Longsor | AWAS Karhutla]
    E --> F[Update Dynamic Hero Banner & Bento Telemetry Cards]
```
