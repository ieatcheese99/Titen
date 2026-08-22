import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/models/user_profile.dart';

final userProfileProvider = StateProvider<UserProfile>((ref) {
  return UserProfile.defaultProfile();
});

final loraGatewayStatusProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'status': 'ONLINE',
    'ssid': 'TITEN-GATEWAY-01',
    'ip': '192.168.4.1',
    'rssi': '-68 dBm',
    'frequency': '915.0 MHz',
    'syncInterval': '10s (Heartbeat 6h)',
    'nodesConnected': 4,
    'totalPacketsReceived': 12480,
    'packetLossRate': '0.12%',
  };
});
