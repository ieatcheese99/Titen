import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Overall zone status calculation for Hero Status Banner
class ZoneStatus {
  final int level; // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
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

  Color get color => getStatusColor(level, hazardType);

  bool get isSafe => level == 0;
  bool get isWarning => level == 1;
  bool get isAlert => level == 2;
  bool get isDanger => level == 3;

  static ZoneStatus safe() {
    return ZoneStatus(
      level: 0,
      hazardType: 0,
      title: 'ALL ZONES SAFE',
      description: 'System Operating Normally. No anomalous environmental readings detected across the network.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus waspadaLongsor() {
    return ZoneStatus(
      level: 1,
      hazardType: 1,
      title: 'WASPADA LONGSOR — ANOMALI RINGAN',
      description: 'Pergerakan mikro terdeteksi pada Node 01 & 04. Kejenuhan tanah meningkat.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus waspadaKarhutla() {
    return ZoneStatus(
      level: 1,
      hazardType: 2,
      title: 'WASPADA KARHUTLA — SUHU TINGGI',
      description: 'Suhu lingkungan meningkat >40°C pada Sektor Hutan Utara. Kelembapan udara menurun.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus siaga() {
    return ZoneStatus(
      level: 2,
      hazardType: 1,
      title: 'SIAGA BENCANA — VALIDASI KONSENSUS',
      description: 'Node sensor mendeteksi anomali kuat. Menunggu validasi 2-dari-3 node.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus awasLongsor() {
    return ZoneStatus(
      level: 3,
      hazardType: 1,
      title: '🔴 AWAS LONGSOR — EVAKUASI SEGERA',
      description: 'KONSENSUS TERVERIFIKASI (≥2 Node): Sudut kemiringan >5.0° & kelembapan tanah >80%. Sirine 120dB aktif.',
      lastUpdated: DateTime.now(),
    );
  }

  static ZoneStatus awasKarhutla() {
    return ZoneStatus(
      level: 3,
      hazardType: 2,
      title: '🔥 AWAS KARHUTLA — TITIK API TERDETEKSI',
      description: 'KONSENSUS TERVERIFIKASI: Suhu udara >45.0°C & kelembapan <25%. Sirine darurat aktif.',
      lastUpdated: DateTime.now(),
    );
  }
}
