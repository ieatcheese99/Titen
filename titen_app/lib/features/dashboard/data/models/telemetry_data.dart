/// Telemetry Data Model reflecting TITEN v2 telemetry contract
/// Measurements are nullable; null indicates unavailable/unsupported reading
class TelemetryData {
  final int nodeId;
  final int? batteryPct;
  final double? tiltDeg;
  final double? soilMoisturePct;
  final double? airTempC;
  final double? airHumidityPct;
  final bool? flameDetected;
  final int? hazardType; // 0: Normal, 1: Longsor, 2: Karhutla, null: unknown
  final int? statusLevel; // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas, null: unknown
  final DateTime? timestamp;
  final DateTime? observedAt;
  final DateTime? receivedAt;
  final String? quality; // 'valid', 'invalid', 'unsupported', 'unavailable'

  TelemetryData({
    required this.nodeId,
    this.batteryPct,
    this.tiltDeg,
    this.soilMoisturePct,
    this.airTempC,
    this.airHumidityPct,
    this.flameDetected,
    this.hazardType,
    this.statusLevel,
    this.timestamp,
    this.observedAt,
    this.receivedAt,
    this.quality,
  });

  bool get isLandslideHazard =>
      (tiltDeg != null && tiltDeg! > 5.0) &&
      (soilMoisturePct != null && soilMoisturePct! > 80.0);

  bool get isKarhutlaHazard =>
      (airTempC != null && airTempC! > 45.0) &&
      (airHumidityPct != null && airHumidityPct! < 25.0);

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    DateTime? parsedTime;
    if (map['timestamp'] != null) {
      parsedTime = DateTime.tryParse(map['timestamp'].toString());
    } else if (map['received_at'] != null) {
      parsedTime = DateTime.tryParse(map['received_at'].toString());
    }

    DateTime? parsedObserved;
    if (map['observed_at'] != null) {
      parsedObserved = DateTime.tryParse(map['observed_at'].toString());
    }

    return TelemetryData(
      nodeId: (map['node_id'] as num?)?.toInt() ?? 1,
      batteryPct: (map['battery_pct'] as num?)?.toInt(),
      tiltDeg: (map['tilt_deg'] as num?)?.toDouble() ??
          (map['tilt_x10'] != null ? (map['tilt_x10'] as num).toDouble() / 10.0 : null),
      soilMoisturePct: (map['soil_moisture_pct'] ?? map['soil_moisture'] as num?)?.toDouble(),
      airTempC: (map['air_temp_c'] as num?)?.toDouble() ??
          (map['air_temp_x10'] != null ? (map['air_temp_x10'] as num).toDouble() / 10.0 : null) ??
          (map['air_temp'] as num?)?.toDouble(),
      airHumidityPct: (map['air_humidity_pct'] ?? map['air_humidity'] as num?)?.toDouble(),
      flameDetected: map['flame_detected'] as bool?,
      hazardType: (map['hazard_type'] as num?)?.toInt(),
      statusLevel: (map['status_level'] as num?)?.toInt(),
      timestamp: parsedTime,
      observedAt: parsedObserved,
      receivedAt: parsedTime,
      quality: map['quality'] is String ? map['quality'] as String : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'node_id': nodeId,
      if (batteryPct != null) 'battery_pct': batteryPct,
      if (tiltDeg != null) 'tilt_deg': tiltDeg,
      if (soilMoisturePct != null) 'soil_moisture_pct': soilMoisturePct,
      if (airTempC != null) 'air_temp_c': airTempC,
      if (airHumidityPct != null) 'air_humidity_pct': airHumidityPct,
      if (flameDetected != null) 'flame_detected': flameDetected,
      if (hazardType != null) 'hazard_type': hazardType,
      if (statusLevel != null) 'status_level': statusLevel,
      if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      if (observedAt != null) 'observed_at': observedAt!.toIso8601String(),
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      if (quality != null) 'quality': quality,
    };
  }

  TelemetryData copyWith({
    int? nodeId,
    int? batteryPct,
    double? tiltDeg,
    double? soilMoisturePct,
    double? airTempC,
    double? airHumidityPct,
    bool? flameDetected,
    int? hazardType,
    int? statusLevel,
    DateTime? timestamp,
    DateTime? observedAt,
    DateTime? receivedAt,
    String? quality,
  }) {
    return TelemetryData(
      nodeId: nodeId ?? this.nodeId,
      batteryPct: batteryPct ?? this.batteryPct,
      tiltDeg: tiltDeg ?? this.tiltDeg,
      soilMoisturePct: soilMoisturePct ?? this.soilMoisturePct,
      airTempC: airTempC ?? this.airTempC,
      airHumidityPct: airHumidityPct ?? this.airHumidityPct,
      flameDetected: flameDetected ?? this.flameDetected,
      hazardType: hazardType ?? this.hazardType,
      statusLevel: statusLevel ?? this.statusLevel,
      timestamp: timestamp ?? this.timestamp,
      observedAt: observedAt ?? this.observedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      quality: quality ?? this.quality,
    );
  }
}
