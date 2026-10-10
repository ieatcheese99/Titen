import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/models/user_profile.dart';
import '../../dashboard/application/dashboard_providers.dart';

final userProfileProvider = StateProvider<UserProfile>((ref) {
  return UserProfile.defaultProfile();
});

/// Gateway status provider consuming real GatewayHealth & Node streams
/// Removing static 915MHz and hardcoded 4 nodes per 03_APP_FLUTTER_SPEC.md §10
final loraGatewayStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final gatewayHealthAsync = ref.watch(gatewayHealthProvider);
  final nodes = ref.watch(allNodesProvider).value ?? [];
  final gateway = gatewayHealthAsync.value;

  final isOnline = gateway?.cloudConnected == true;
  final radioBand = gateway?.radioBand ?? '433.0 MHz (SX1278)';
  final activeNodes = nodes.where((n) => n.isOnline).length;

  return {
    'status': isOnline ? 'ONLINE' : (gateway != null ? 'DEGRADED' : 'BELUM TERDAFTAR'),
    'gatewayId': gateway?.gatewayId ?? 'gateway_01',
    'cloudConnected': isOnline,
    'loraActive': gateway?.loraReceiverActive ?? false,
    'frequency': radioBand,
    'lastHeartbeat': gateway?.lastHeartbeat?.toIso8601String() ?? '—',
    'firmware': gateway?.firmwareVersion ?? 'v2.1-esp32',
    'nodesConnected': activeNodes,
    'totalRegistered': nodes.length,
    'backlogCount': gateway?.backlogCount ?? 0,
  };
});
