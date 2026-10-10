/// Gateway health status model per 03_APP_FLUTTER_SPEC.md §3.1 & §4.2
class GatewayHealth {
  final String? gatewayId;
  final bool cloudConnected;
  final bool loraReceiverActive;
  final DateTime? lastHeartbeat;
  final String? firmwareVersion;
  final String? radioBand; // e.g. '433 MHz' per firmware audit, not assumed 915 MHz
  final int backlogCount;
  final String status; // 'online', 'degraded', 'offline', 'unknown'

  const GatewayHealth({
    this.gatewayId,
    required this.cloudConnected,
    required this.loraReceiverActive,
    this.lastHeartbeat,
    this.firmwareVersion,
    this.radioBand,
    this.backlogCount = 0,
    required this.status,
  });

  factory GatewayHealth.unknown() {
    return const GatewayHealth(
      gatewayId: null,
      cloudConnected: false,
      loraReceiverActive: false,
      lastHeartbeat: null,
      firmwareVersion: null,
      radioBand: null,
      backlogCount: 0,
      status: 'unknown',
    );
  }

  factory GatewayHealth.fromMap(Map<String, dynamic> map, [String? id]) {
    DateTime? parsedHeartbeat;
    if (map['last_heartbeat'] != null) {
      parsedHeartbeat = DateTime.tryParse(map['last_heartbeat'].toString());
    }

    return GatewayHealth(
      gatewayId: id ?? map['gateway_id'] as String?,
      cloudConnected: map['cloud_connected'] as bool? ?? false,
      loraReceiverActive: map['lora_receiver_active'] as bool? ?? false,
      lastHeartbeat: parsedHeartbeat,
      firmwareVersion: map['firmware_version'] as String?,
      radioBand: map['radio_band'] as String? ?? map['frequency'] as String?,
      backlogCount: (map['backlog_count'] as num?)?.toInt() ?? 0,
      status: map['status'] as String? ?? 'unknown',
    );
  }
}
