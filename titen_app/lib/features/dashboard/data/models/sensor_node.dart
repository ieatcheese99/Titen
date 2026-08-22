import 'telemetry_data.dart';

/// Sensor Node model mapping to nodes/{nodeId} Firestore document
class SensorNode {
  final int nodeId;
  final String name;
  final double latitude;
  final double longitude;
  final String nodeType; // 'landslide', 'karhutla', 'combo'
  final int lastStatusLevel; // 0: Aman, 1: Waspada, 2: Siaga, 3: Awas
  final int lastHazardType; // 0: Normal, 1: Longsor, 2: Karhutla
  final int batteryPct;
  final int loraRssi; // dBm e.g. -78
  final double loraSnr; // dB e.g. 9.5
  final DateTime lastSeen;
  final TelemetryData? lastTelemetry;

  SensorNode({
    required this.nodeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.nodeType,
    required this.lastStatusLevel,
    required this.lastHazardType,
    required this.batteryPct,
    required this.loraRssi,
    required this.loraSnr,
    required this.lastSeen,
    this.lastTelemetry,
  });

  String get statusText {
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
        return 'Normal';
    }
  }

  String get hazardTypeText {
    switch (lastHazardType) {
      case 1:
        return 'Tanah Longsor';
      case 2:
        return 'Kebakaran Hutan';
      default:
        return 'Normal';
    }
  }

  bool get isOnline {
    return DateTime.now().difference(lastSeen).inHours < 8;
  }

  factory SensorNode.fromMap(Map<String, dynamic> map, [String? id]) {
    return SensorNode(
      nodeId: (map['node_id'] as num?)?.toInt() ?? int.tryParse(id ?? '1') ?? 1,
      name: map['name'] as String? ?? 'Sensor Node',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.9147,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 107.6098,
      nodeType: map['node_type'] as String? ?? 'combo',
      lastStatusLevel: (map['last_status_level'] as num?)?.toInt() ?? 0,
      lastHazardType: (map['last_hazard_type'] as num?)?.toInt() ?? 0,
      batteryPct: (map['battery_pct'] as num?)?.toInt() ?? 100,
      loraRssi: (map['lora_rssi'] as num?)?.toInt() ?? -75,
      loraSnr: (map['lora_snr'] as num?)?.toDouble() ?? 9.0,
      lastSeen: map['last_seen'] != null
          ? DateTime.tryParse(map['last_seen'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastTelemetry: map['last_telemetry'] != null
          ? TelemetryData.fromMap(map['last_telemetry'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'node_id': nodeId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'node_type': nodeType,
      'last_status_level': lastStatusLevel,
      'last_hazard_type': lastHazardType,
      'battery_pct': batteryPct,
      'lora_rssi': loraRssi,
      'lora_snr': loraSnr,
      'last_seen': lastSeen.toIso8601String(),
      if (lastTelemetry != null) 'last_telemetry': lastTelemetry!.toMap(),
    };
  }

  SensorNode copyWith({
    int? nodeId,
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
    TelemetryData? lastTelemetry,
  }) {
    return SensorNode(
      nodeId: nodeId ?? this.nodeId,
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
      lastTelemetry: lastTelemetry ?? this.lastTelemetry,
    );
  }
}
