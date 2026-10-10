import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import '../models/gateway_health.dart';
import '../../../../core/constants/hazard_constants.dart';
import 'node_repository.dart';

/// Repository connected to Firebase Realtime Database
/// Conforming to TITEN Contract V2 with legacy V1 fallback adapter
/// Strictly WITHOUT mock fallback per 03_APP_FLUTTER_SPEC.md §3 & §10
class FirebaseNodeRepository implements NodeRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  StreamSubscription<DatabaseEvent>? _nodesSub;
  StreamSubscription<DatabaseEvent>? _alertsSub;
  StreamSubscription<DatabaseEvent>? _gatewaySub;

  final _nodesController = StreamController<List<SensorNode>>.broadcast();
  final _alertsController = StreamController<List<AlertModel>>.broadcast();
  final _gatewayController = StreamController<GatewayHealth>.broadcast();

  FirebaseNodeRepository() {
    _initStreams();
  }

  void _initStreams() {
    // 1. Listen to Realtime Nodes in Firebase (supports 'nodes' and 'registry/nodes')
    _nodesSub = _db.ref('nodes').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) {
          _nodesController.add([]);
          return;
        }

        try {
          final List<SensorNode> nodes = [];
          if (data is Map) {
            data.forEach((key, val) {
              if (val is Map) {
                final map = Map<String, dynamic>.from(val);
                final rawNodeId = (map['node_id'] as num?)?.toInt() ??
                    int.tryParse(key.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
                    1;
                
                // Read nullable telemetry values (no fake 100% or 0.0)
                final tilt = (map['tilt_deg'] as num?)?.toDouble() ??
                    (map['tilt_x10'] != null ? (map['tilt_x10'] as num).toDouble() / 10.0 : null);
                final soil = (map['soil_moisture_pct'] ?? map['soil_moisture'] as num?)?.toDouble();
                final temp = (map['air_temp_c'] as num?)?.toDouble() ??
                    (map['air_temp_x10'] != null ? (map['air_temp_x10'] as num).toDouble() / 10.0 : null) ??
                    (map['air_temp'] as num?)?.toDouble();
                final hum = (map['air_humidity_pct'] ?? map['air_humidity'] as num?)?.toDouble();
                final flame = map['flame_detected'] as bool?;
                final hazard = (map['hazard_type'] as num?)?.toInt();
                final status = (map['status_level'] as num?)?.toInt();
                final bat = (map['battery_pct'] as num?)?.toInt();
                final rssi = (map['rssi'] ?? map['lora_rssi'] as num?)?.toInt();
                final snr = (map['snr'] ?? map['lora_snr'] as num?)?.toDouble();

                DateTime? timestamp;
                if (map['received_at'] != null) {
                  timestamp = DateTime.tryParse(map['received_at'].toString());
                } else if (map['timestamp'] != null) {
                  timestamp = DateTime.tryParse(map['timestamp'].toString());
                } else if (map['timestamp_rtc'] != null) {
                  final rtc = (map['timestamp_rtc'] as num).toInt();
                  if (rtc > 1600000000) {
                    timestamp = DateTime.fromMillisecondsSinceEpoch(rtc * 1000);
                  }
                }

                final telemetry = (tilt != null || soil != null || temp != null || hum != null)
                    ? TelemetryData(
                        nodeId: rawNodeId,
                        batteryPct: bat,
                        tiltDeg: tilt,
                        soilMoisturePct: soil,
                        airTempC: temp,
                        airHumidityPct: hum,
                        flameDetected: flame,
                        hazardType: hazard,
                        statusLevel: status,
                        timestamp: timestamp,
                        receivedAt: timestamp,
                      )
                    : null;

                nodes.add(
                  SensorNode(
                    nodeId: rawNodeId,
                    nodeKey: map['node_key'] as String? ?? 'node_${rawNodeId.toString().padLeft(2, '0')}',
                    name: map['name'] as String? ?? 'Node ${rawNodeId.toString().padLeft(2, '0')}',
                    latitude: (map['latitude'] as num?)?.toDouble(),
                    longitude: (map['longitude'] as num?)?.toDouble(),
                    nodeType: map['node_type'] as String?,
                    lastStatusLevel: status,
                    lastHazardType: hazard,
                    batteryPct: bat,
                    loraRssi: rssi,
                    loraSnr: snr,
                    lastSeen: timestamp,
                    receivedAt: timestamp,
                    lastTelemetry: telemetry,
                  ),
                );
              }
            });
          }

          _nodesController.add(nodes);
        } catch (e) {
          _nodesController.addError(e);
        }
      },
      onError: (err) {
        _nodesController.addError(err);
      },
    );

    // 2. Listen to Alerts in Firebase
    _alertsSub = _db.ref('alerts').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) {
          _alertsController.add([]);
          return;
        }

        try {
          final List<AlertModel> alerts = [];
          if (data is Map) {
            data.forEach((key, val) {
              if (val is Map) {
                alerts.add(AlertModel.fromMap(Map<String, dynamic>.from(val), key.toString()));
              }
            });
          }
          _alertsController.add(alerts);
        } catch (e) {
          _alertsController.addError(e);
        }
      },
      onError: (err) {
        _alertsController.addError(err);
      },
    );

    // 3. Listen to Gateway Status
    _gatewaySub = _db.ref('gateway_status').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          _gatewayController.add(GatewayHealth.unknown());
          return;
        }
        try {
          final firstVal = data.values.firstOrNull;
          if (firstVal is Map) {
            _gatewayController.add(GatewayHealth.fromMap(Map<String, dynamic>.from(firstVal)));
          } else {
            _gatewayController.add(GatewayHealth.fromMap(Map<String, dynamic>.from(data)));
          }
        } catch (_) {
          _gatewayController.add(GatewayHealth.unknown());
        }
      },
      onError: (_) {
        _gatewayController.add(GatewayHealth.unknown());
      },
    );
  }

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    return _nodesController.stream;
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    return watchAllNodes().map(
      (nodes) => nodes.where((n) => n.nodeId == nodeId).firstOrNull,
    );
  }

  @override
  Stream<GatewayHealth> watchGatewayHealth() {
    return _gatewayController.stream;
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    // Read from /history/node_0X or fallback to query
    final nodeKey = 'node_${nodeId.toString().padLeft(2, '0')}';
    return _db.ref('history/$nodeKey').limitToLast(50).onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return <TelemetryData>[];

      final List<TelemetryData> history = [];
      data.forEach((key, val) {
        if (val is Map) {
          history.add(TelemetryData.fromMap(Map<String, dynamic>.from(val)));
        }
      });
      history.sort((a, b) => (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0)));
      return history;
    });
  }

  @override
  Stream<List<AlertModel>> watchAlerts() {
    return _alertsController.stream;
  }

  @override
  Future<bool> acknowledgeAlert(String alertId, String actor) async {
    try {
      await _db.ref('alerts/$alertId').update({
        'acknowledged': true,
        'acknowledged_at': DateTime.now().toIso8601String(),
        'acknowledged_by': actor,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> resolveAlert(String alertId) async {
    try {
      await _db.ref('alerts/$alertId').update({
        'resolved': true,
        'resolved_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> triggerSirenCommand(int nodeId, bool enable, {int durationSec = 30}) async {
    try {
      final commandId = 'cmd_${DateTime.now().millisecondsSinceEpoch}';
      await _db.ref('commands/$commandId').set({
        'command_id': commandId,
        'target_node_id': nodeId,
        'action': enable ? 'SIREN_ON' : 'SIREN_OFF',
        'duration_sec': durationSec,
        'status': 'requested',
        'requested_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> triggerSirenTest(String pin) async {
    if (pin != HazardConstants.defaultSirenPin) return false;
    return triggerSirenCommand(1, true, durationSec: 10);
  }

  @override
  void triggerSimulation(String mode) {
    // In Live mode, simulations are not applied
  }

  @override
  void dispose() {
    _nodesSub?.cancel();
    _alertsSub?.cancel();
    _gatewaySub?.cancel();
    _nodesController.close();
    _alertsController.close();
    _gatewayController.close();
  }
}
