import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Overall zone status calculation for Hero Status Banner
/// Conforming to 03_APP_FLUTTER_SPEC.md §3.1 & 04_RESPONSIVE_MATRIX.md §3
class ZoneStatus {
  final int level; // -1: Belum Dinilai/Unknown, 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
  final int hazardType; // 0: Normal, 1: Longsor, 2: Karhutla
  final String title;
  final String description;
  final DateTime lastUpdated;

  const ZoneStatus({
    required this.level,
    required this.hazardType,
    required this.title,
    required this.description,
    required this.lastUpdated,
  });

  Color get color {
    if (level < 0) return TitenColors.textMuted;
    return getStatusColor(level, hazardType);
  }

  bool get isUnknown => level < 0;
  bool get isSafe => level == 0;
  bool get isWarning => level == 1;
  bool get isAlert => level == 2;
  bool get isDanger => level == 3;

  static ZoneStatus unknown([String? reason]) {
    return ZoneStatus(
      level: -1,
      hazardType: 0,
      title: 'STATUS BELUM DAPAT DINILAI',
      description: reason ?? 'Menunggu paket telemetri valid dari gateway atau registry perangkat.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus loading() {
    return ZoneStatus(
      level: -1,
      hazardType: 0,
      title: 'MEMERIKSA EVALUASI SENSOR...',
      description: 'Menghubungkan ke layanan data dan memvalidasi integritas sinyal telemetri.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus safe() {
    return ZoneStatus(
      level: 0,
      hazardType: 0,
      title: 'SELURUH ZONA TERVERIFIKASI AMAN',
      description: 'Semua node fresh beroperasi normal. Tidak ada anomali terdeteksi.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus waspadaLongsor() {
    return ZoneStatus(
      level: 1,
      hazardType: 1,
      title: 'WASPADA LONGSOR — ANOMALI RINGAN',
      description: 'Pergerakan mikro terdeteksi pada lereng. Kejenuhan tanah meningkat.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus waspadaKarhutla() {
    return ZoneStatus(
      level: 1,
      hazardType: 2,
      title: 'WASPADA KARHUTLA — SUHU TINGGI',
      description: 'Suhu lingkungan meningkat >40°C pada area hutan. Kelembapan udara menurun.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus siaga() {
    return ZoneStatus(
      level: 2,
      hazardType: 1,
      title: 'SIAGA BENCANA — EVALUASI ANOMALI',
      description: 'Node sensor mendeteksi ambang anomali signifikan.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus awasLongsor() {
    return ZoneStatus(
      level: 3,
      hazardType: 1,
      title: '🔴 AWAS LONGSOR — PERINGATAN KRITIS',
      description: 'KONSENSUS TERVERIFIKASI: Kemiringan dan kelembapan melebihi ambang batas aman.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus awasKarhutla() {
    return ZoneStatus(
      level: 3,
      hazardType: 2,
      title: '🔥 AWAS KARHUTLA — TITIK API TERDETEKSI',
      description: 'KONSENSUS TERVERIFIKASI: Suhu ekstrem dan kelembapan udara kritis terdeteksi.',
      lastUpdated: DateTime.now(),
    );
  }
}
