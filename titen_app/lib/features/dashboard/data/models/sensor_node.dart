import 'telemetry_data.dart';

/// Enum for node packet freshness per 03_APP_FLUTTER_SPEC.md §3.2 & 04_RESPONSIVE_MATRIX.md §3
enum FreshnessStatus {
  fresh,
  stale,
  missing,
  unknown;

  String get label {
    switch (this) {
      case FreshnessStatus.fresh:
        return 'Data Terbaru';
      case FreshnessStatus.stale:
        return 'Data Terlambat';
      case FreshnessStatus.missing:
        return 'Laporan Belum Diterima';
      case FreshnessStatus.unknown:
        return 'Kesegaran Belum Dinilai';
    }
  }
}

/// Sensor Node model mapping to TITEN contract v2 / legacy adapter
/// Nullable measurements and metadata; no fake defaults per 03_APP_FLUTTER_SPEC.md §3 & §10
class SensorNode {
  final int nodeId;
  final String nodeKey;
  final String name;
  final double? latitude;
  final double? longitude;
  final String? nodeType; // 'landslide', 'karhutla', 'combo'
  final int?
  lastStatusLevel; // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas, null: belum dinilai
  final int?
  lastHazardType; // 0: Normal, 1: Longsor, 2: Karhutla, null: unknown
  final int? batteryPct; // null if unmeasured/uncalibrated
  final int? loraRssi; // dBm e.g. -78, null if unavailable
  final double? loraSnr; // dB e.g. 9.5, null if unavailable
  final DateTime? lastSeen;
  final DateTime? receivedAt;
  final DateTime? observedAt;
  final TelemetryData? lastTelemetry;
  final int expectedReportIntervalMs; // R
  final int deliveryGraceMs; // J

  SensorNode({
    required this.nodeId,
    String? nodeKey,
    String? name,
    this.latitude,
    this.longitude,
    this.nodeType,
    this.lastStatusLevel,
    this.lastHazardType,
    this.batteryPct,
    this.loraRssi,
    this.loraSnr,
    this.lastSeen,
    this.receivedAt,
    this.observedAt,
    this.lastTelemetry,
    this.expectedReportIntervalMs = 60000,
    this.deliveryGraceMs = 15000,
  }) : nodeKey = nodeKey ?? 'node_${nodeId.toString().padLeft(2, '0')}',
       name = name ?? 'Node ${nodeId.toString().padLeft(2, '0')}';

  /// Freshness calculation adhering to R/J formula:
  /// age = now - received_at
  /// fresh: age <= R + J
  /// stale: R + J < age <= 3R + J
  /// missing: age > 3R + J
  FreshnessStatus getFreshness([DateTime? trustedNow]) {
    final now = trustedNow ?? DateTime.now();
    final refTime = receivedAt ?? lastSeen;
    if (refTime == null) return FreshnessStatus.unknown;

    final ageMs = now.difference(refTime).inMilliseconds;
    if (ageMs < 0) {
      return FreshnessStatus.unknown; // Clock skew or invalid future timestamp
    }

    final r = expectedReportIntervalMs;
    final j = deliveryGraceMs;
    if (ageMs <= r + j) return FreshnessStatus.fresh;
    if (ageMs <= (3 * r) + j) return FreshnessStatus.stale;
    return FreshnessStatus.missing;
  }

  /// Backward-compatible getter: returns true only if data is fresh
  bool get isOnline => getFreshness() == FreshnessStatus.fresh;

  /// Only geodetic coordinates may be used for map markers or elevation lookup.
  bool get hasValidCoordinates {
    final lat = latitude;
    final lon = longitude;
    return lat != null &&
        lon != null &&
        lat.isFinite &&
        lon.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lon >= -180 &&
        lon <= 180;
  }

  String get statusText {
    if (lastStatusLevel == null) return 'Belum Dinilai';
    switch (lastStatusLevel) {
      case 0:
        return 'Aman';
      case 1:
        return 'Waspada';
      case 2:
        return 'Siaga';
      case 3:
        return lastHazardType == 2 ? 'AWAS KARHUTLA' : 'AWAS LONGSOR';
      default:
        return 'Belum Dinilai';
    }
  }

  String get hazardTypeText {
    if (lastHazardType == null) return 'Tidak Diketahui';
    switch (lastHazardType) {
      case 1:
        return 'Tanah Longsor';
      case 2:
        return 'Kebakaran Hutan';
      default:
        return 'Normal';
    }
  }

  factory SensorNode.fromMap(Map<String, dynamic> map, [String? id]) {
    final rawNodeId =
        (map['node_id'] as num?)?.toInt() ??
        int.tryParse((id ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
        1;
    final nodeKey =
        map['node_key'] as String? ??
        'node_${rawNodeId.toString().padLeft(2, '0')}';

    DateTime? parsedReceived;
    if (map['received_at'] != null) {
      parsedReceived = DateTime.tryParse(map['received_at'].toString());
    }

    DateTime? parsedObserved;
    if (map['observed_at'] != null) {
      parsedObserved = DateTime.tryParse(map['observed_at'].toString());
    }

    DateTime? parsedLastSeen;
    if (map['last_seen'] != null) {
      parsedLastSeen = DateTime.tryParse(map['last_seen'].toString());
    } else if (map['timestamp_rtc'] != null) {
      final rtc = (map['timestamp_rtc'] as num).toInt();
      // Only treat as Unix epoch if it's large enough (> 1600000000), otherwise it's device uptime
      if (rtc > 1600000000) {
        parsedLastSeen = DateTime.fromMillisecondsSinceEpoch(rtc * 1000);
      }
    }

    return SensorNode(
      nodeId: rawNodeId,
      nodeKey: nodeKey,
      name: map['name'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      nodeType: map['node_type'] as String?,
      lastStatusLevel: (map['last_status_level'] ?? map['status_level'] as num?)
          ?.toInt(),
      lastHazardType: (map['last_hazard_type'] ?? map['hazard_type'] as num?)
          ?.toInt(),
      batteryPct: (map['battery_pct'] as num?)?.toInt(),
      loraRssi: (map['lora_rssi'] ?? map['rssi'] as num?)?.toInt(),
      loraSnr: (map['lora_snr'] ?? map['snr'] as num?)?.toDouble(),
      lastSeen: parsedLastSeen ?? parsedReceived,
      receivedAt: parsedReceived,
      observedAt: parsedObserved,
      expectedReportIntervalMs:
          (map['expected_report_interval_ms'] as num?)?.toInt() ?? 60000,
      deliveryGraceMs: (map['delivery_grace_ms'] as num?)?.toInt() ?? 15000,
      lastTelemetry: map['last_telemetry'] != null
          ? TelemetryData.fromMap(map['last_telemetry'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'node_id': nodeId,
      'node_key': nodeKey,
      'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (nodeType != null) 'node_type': nodeType,
      if (lastStatusLevel != null) 'last_status_level': lastStatusLevel,
      if (lastHazardType != null) 'last_hazard_type': lastHazardType,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (loraRssi != null) 'lora_rssi': loraRssi,
      if (loraSnr != null) 'lora_snr': loraSnr,
      if (lastSeen != null) 'last_seen': lastSeen!.toIso8601String(),
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      if (observedAt != null) 'observed_at': observedAt!.toIso8601String(),
      if (lastTelemetry != null) 'last_telemetry': lastTelemetry!.toMap(),
    };
  }

  SensorNode copyWith({
    int? nodeId,
    String? nodeKey,
    String? name,
    double? latitude,
    double? longitude,
    String? nodeType,
    int? lastStatusLevel,
    int? lastHazardType,
    int? batteryPct,
    int? loraRssi,
    double? loraSnr,
    DateTime? lastSeen,
    DateTime? receivedAt,
    DateTime? observedAt,
    TelemetryData? lastTelemetry,
    int? expectedReportIntervalMs,
    int? deliveryGraceMs,
  }) {
    return SensorNode(
      nodeId: nodeId ?? this.nodeId,
      nodeKey: nodeKey ?? this.nodeKey,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nodeType: nodeType ?? this.nodeType,
      lastStatusLevel: lastStatusLevel ?? this.lastStatusLevel,
      lastHazardType: lastHazardType ?? this.lastHazardType,
      batteryPct: batteryPct ?? this.batteryPct,
      loraRssi: loraRssi ?? this.loraRssi,
      loraSnr: loraSnr ?? this.loraSnr,
      lastSeen: lastSeen ?? this.lastSeen,
      receivedAt: receivedAt ?? this.receivedAt,
      observedAt: observedAt ?? this.observedAt,
      lastTelemetry: lastTelemetry ?? this.lastTelemetry,
      expectedReportIntervalMs:
          expectedReportIntervalMs ?? this.expectedReportIntervalMs,
      deliveryGraceMs: deliveryGraceMs ?? this.deliveryGraceMs,
    );
  }
}
