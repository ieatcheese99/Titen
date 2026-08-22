/// Telemetry Data Model reflecting TitenPayload (16 bytes packed binary from ESP32 Edge)
class TelemetryData {
  final int nodeId;
  final int batteryPct;
  final double tiltDeg;
  final double soilMoisturePct;
  final double airTempC;
  final double airHumidityPct;
  final int hazardType; // 0: Normal, 1: Longsor, 2: Karhutla
  final int statusLevel; // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
  final DateTime timestamp;

  TelemetryData({
    required this.nodeId,
    required this.batteryPct,
    required this.tiltDeg,
    required this.soilMoisturePct,
    required this.airTempC,
    required this.airHumidityPct,
    required this.hazardType,
    required this.statusLevel,
    required this.timestamp,
  });

  bool get isLandslideHazard =>
      tiltDeg > 5.0 && soilMoisturePct > 80.0;

  bool get isKarhutlaHazard =>
      airTempC > 45.0 && airHumidityPct < 25.0;

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      nodeId: (map['node_id'] as num?)?.toInt() ?? 1,
      batteryPct: (map['battery_pct'] as num?)?.toInt() ?? 100,
      tiltDeg: (map['tilt_deg'] as num?)?.toDouble() ?? 0.0,
      soilMoisturePct: (map['soil_moisture_pct'] as num?)?.toDouble() ?? 0.0,
      airTempC: (map['air_temp_c'] as num?)?.toDouble() ?? 25.0,
      airHumidityPct: (map['air_humidity_pct'] as num?)?.toDouble() ?? 50.0,
      hazardType: (map['hazard_type'] as num?)?.toInt() ?? 0,
      statusLevel: (map['status_level'] as num?)?.toInt() ?? 0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'node_id': nodeId,
      'battery_pct': batteryPct,
      'tilt_deg': tiltDeg,
      'soil_moisture_pct': soilMoisturePct,
      'air_temp_c': airTempC,
      'air_humidity_pct': airHumidityPct,
      'hazard_type': hazardType,
      'status_level': statusLevel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  TelemetryData copyWith({
    int? nodeId,
    int? batteryPct,
    double? tiltDeg,
    double? soilMoisturePct,
    double? airTempC,
    double? airHumidityPct,
    int? hazardType,
    int? statusLevel,
    DateTime? timestamp,
  }) {
    return TelemetryData(
      nodeId: nodeId ?? this.nodeId,
      batteryPct: batteryPct ?? this.batteryPct,
      tiltDeg: tiltDeg ?? this.tiltDeg,
      soilMoisturePct: soilMoisturePct ?? this.soilMoisturePct,
      airTempC: airTempC ?? this.airTempC,
      airHumidityPct: airHumidityPct ?? this.airHumidityPct,
      hazardType: hazardType ?? this.hazardType,
      statusLevel: statusLevel ?? this.statusLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
