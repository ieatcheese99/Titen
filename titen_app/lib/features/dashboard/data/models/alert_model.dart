/// Disaster Alert Model representing results from Multi-Node Consensus Engine
class AlertModel {
  final String id;
  final int hazardType; // 1: Longsor, 2: Karhutla
  final int statusLevel; // usually 3 (Awas)
  final List<int> nodeIds; // e.g. [1, 2] (consensus >= 2 of 3)
  final DateTime confirmedAt;
  final double latitude;
  final double longitude;
  final bool resolved;
  final DateTime? resolvedAt;
  final String title;
  final String description;

  AlertModel({
    required this.id,
    required this.hazardType,
    required this.statusLevel,
    required this.nodeIds,
    required this.confirmedAt,
    required this.latitude,
    required this.longitude,
    required this.resolved,
    this.resolvedAt,
    required this.title,
    required this.description,
  });

  String get hazardName => hazardType == 2 ? 'Kebakaran Hutan' : 'Tanah Longsor';

  factory AlertModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return AlertModel(
      id: docId ?? map['id']?.toString() ?? 'alert_default',
      hazardType: (map['hazard_type'] as num?)?.toInt() ?? 1,
      statusLevel: (map['status_level'] as num?)?.toInt() ?? 3,
      nodeIds: (map['node_ids'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [1, 2],
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.tryParse(map['confirmed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? -6.9147,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 107.6098,
      resolved: map['resolved'] as bool? ?? false,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'].toString())
          : null,
      title: map['title'] as String? ?? 'Peringatan Bencana',
      description: map['description'] as String? ?? 'Anomali terdeteksi oleh multi-node sensor.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hazard_type': hazardType,
      'status_level': statusLevel,
      'node_ids': nodeIds,
      'confirmed_at': confirmedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'resolved': resolved,
      'resolved_at': resolvedAt?.toIso8601String(),
      'title': title,
      'description': description,
    };
  }
}
