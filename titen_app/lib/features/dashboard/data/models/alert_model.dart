/// Lifecycle of a disaster alert per 03_APP_FLUTTER_SPEC.md §8
enum AlertLifecycle {
  open,
  acknowledged,
  resolved;

  String get label {
    switch (this) {
      case AlertLifecycle.open:
        return 'Aktif';
      case AlertLifecycle.acknowledged:
        return 'Diakui';
      case AlertLifecycle.resolved:
        return 'Selesai';
    }
  }
}

/// Disaster Alert Model
/// Valid level/lifecycle/evidence; no fake default [1,2] or synthetic coordinates
class AlertModel {
  final String id;
  final int? hazardType; // 1: Longsor, 2: Karhutla, null: belum dinilai
  final int? statusLevel; // 1: Waspada, 2: Siaga, 3: Awas
  final List<int> nodeIds;
  final DateTime? confirmedAt;
  final DateTime? receivedAt;
  final double? latitude;
  final double? longitude;
  final bool resolved;
  final DateTime? resolvedAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final String title;
  final String description;
  final List<String> evidenceEventIds;

  AlertModel({
    required this.id,
    this.hazardType,
    this.statusLevel,
    required this.nodeIds,
    this.confirmedAt,
    this.receivedAt,
    this.latitude,
    this.longitude,
    this.resolved = false,
    this.resolvedAt,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    required this.title,
    required this.description,
    this.evidenceEventIds = const [],
  });

  String get hazardName {
    if (hazardType == 2) return 'Kebakaran Hutan';
    if (hazardType == 1) return 'Tanah Longsor';
    return 'Anomali Lingkungan';
  }

  AlertLifecycle get lifecycle {
    if (resolved) return AlertLifecycle.resolved;
    if (acknowledged) return AlertLifecycle.acknowledged;
    return AlertLifecycle.open;
  }

  factory AlertModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final alertId = docId ?? map['id']?.toString() ?? 'alert_${DateTime.now().millisecondsSinceEpoch}';

    DateTime? parsedConfirmed;
    if (map['confirmed_at'] != null) {
      parsedConfirmed = DateTime.tryParse(map['confirmed_at'].toString());
    } else if (map['occurred_at'] != null) {
      parsedConfirmed = DateTime.tryParse(map['occurred_at'].toString());
    }

    DateTime? parsedReceived;
    if (map['received_at'] != null) {
      parsedReceived = DateTime.tryParse(map['received_at'].toString());
    }

    final rawNodeIds = map['node_ids'];
    final List<int> parsedNodeIds = [];
    if (rawNodeIds is List) {
      for (final item in rawNodeIds) {
        if (item is num) parsedNodeIds.add(item.toInt());
      }
    } else if (map['node_id'] is num) {
      parsedNodeIds.add((map['node_id'] as num).toInt());
    }

    return AlertModel(
      id: alertId,
      hazardType: (map['hazard_type'] as num?)?.toInt(),
      statusLevel: (map['status_level'] as num?)?.toInt(),
      nodeIds: parsedNodeIds,
      confirmedAt: parsedConfirmed,
      receivedAt: parsedReceived ?? parsedConfirmed,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      resolved: map['resolved'] as bool? ?? false,
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'].toString())
          : null,
      acknowledged: map['acknowledged'] as bool? ?? false,
      acknowledgedAt: map['acknowledged_at'] != null
          ? DateTime.tryParse(map['acknowledged_at'].toString())
          : null,
      acknowledgedBy: map['acknowledged_by'] as String?,
      title: map['title'] as String? ?? 'Peringatan Anomali Sensor',
      description: map['description'] as String? ?? 'Anomali terdeteksi oleh sistem telemetri.',
      evidenceEventIds: (map['evidence_event_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (hazardType != null) 'hazard_type': hazardType,
      if (statusLevel != null) 'status_level': statusLevel,
      'node_ids': nodeIds,
      if (confirmedAt != null) 'confirmed_at': confirmedAt!.toIso8601String(),
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'resolved': resolved,
      if (resolvedAt != null) 'resolved_at': resolvedAt!.toIso8601String(),
      'acknowledged': acknowledged,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt!.toIso8601String(),
      if (acknowledgedBy != null) 'acknowledged_by': acknowledgedBy,
      'title': title,
      'description': description,
      'evidence_event_ids': evidenceEventIds,
    };
  }

  AlertModel copyWith({
    String? id,
    int? hazardType,
    int? statusLevel,
    List<int>? nodeIds,
    DateTime? confirmedAt,
    DateTime? receivedAt,
    double? latitude,
    double? longitude,
    bool? resolved,
    DateTime? resolvedAt,
    bool? acknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    String? title,
    String? description,
    List<String>? evidenceEventIds,
  }) {
    return AlertModel(
      id: id ?? this.id,
      hazardType: hazardType ?? this.hazardType,
      statusLevel: statusLevel ?? this.statusLevel,
      nodeIds: nodeIds ?? this.nodeIds,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      title: title ?? this.title,
      description: description ?? this.description,
      evidenceEventIds: evidenceEventIds ?? this.evidenceEventIds,
    );
  }
}
