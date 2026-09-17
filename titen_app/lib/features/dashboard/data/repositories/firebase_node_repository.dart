import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import 'node_repository.dart';
import 'mock_node_repository.dart';

/// Repository connected to Firebase Realtime Database
class FirebaseNodeRepository implements NodeRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final MockNodeRepository _mockFallback = MockNodeRepository();

  StreamSubscription<DatabaseEvent>? _nodesSub;
  StreamSubscription<DatabaseEvent>? _alertsSub;

  final _nodesController = StreamController<List<SensorNode>>.broadcast();
  final _alertsController = StreamController<List<AlertModel>>.broadcast();

  FirebaseNodeRepository() {
    _initStreams();
  }

  void _initStreams() {
    // 1. Listen to Realtime Nodes in Firebase
    _nodesSub = _db.ref('nodes').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) {
          return;
        }

        try {
          final List<SensorNode> nodes = [];
          if (data is Map) {
            data.forEach((key, val) {
              if (val is Map) {
                final nodeId = int.tryParse(key.toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
                final tilt = ((val['tilt_x10'] ?? (val['tilt_deg'] != null ? (val['tilt_deg'] as num) * 10 : 0)) as num).toDouble() / 10.0;
                final soil = ((val['soil_moisture'] ?? val['soil_moisture_pct'] ?? 0) as num).toDouble();
                final temp = ((val['air_temp_x10'] ?? (val['air_temp'] != null ? (val['air_temp'] as num) * 10 : 0)) as num).toDouble() / 10.0;
                final hum = ((val['air_humidity'] ?? val['air_humidity_pct'] ?? 0) as num).toDouble();
                final hazard = ((val['hazard_type'] ?? 0) as num).toInt();
                final status = ((val['status_level'] ?? 0) as num).toInt();
                final bat = ((val['battery_pct'] ?? 100) as num).toInt();
                final rssi = ((val['rssi'] ?? -75) as num).toInt();
                final snr = ((val['snr'] ?? 9.0) as num).toDouble();
                final timeSec = ((val['timestamp_rtc'] ?? 0) as num).toInt();
                final timestamp = timeSec > 0
                    ? DateTime.fromMillisecondsSinceEpoch(timeSec * 1000)
                    : DateTime.now();

                final telemetry = TelemetryData(
                  nodeId: nodeId,
                  batteryPct: bat,
                  tiltDeg: tilt,
                  soilMoisturePct: soil,
                  airTempC: temp,
                  airHumidityPct: hum,
                  hazardType: hazard,
                  statusLevel: status,
                  timestamp: timestamp,
                );

                nodes.add(
                  SensorNode(
                    nodeId: nodeId,
                    name: 'Node 0$nodeId - TITEN Lereng',
                    latitude: -6.9125 + (nodeId * 0.003),
                    longitude: 107.6045 + (nodeId * 0.003),
                    nodeType: hazard == 2 ? 'karhutla' : 'landslide',
                    lastStatusLevel: status,
                    lastHazardType: hazard,
                    batteryPct: bat,
                    loraRssi: rssi,
                    loraSnr: snr,
                    lastSeen: timestamp,
                    lastTelemetry: telemetry,
                  ),
                );
              }
            });
          }

          if (nodes.isNotEmpty) {
            _nodesController.add(nodes);
          }
        } catch (_) {}
      },
    );

    // 2. Listen to Alerts in Firebase
    _alertsSub = _db.ref('alerts').onValue.listen(
      (event) {
        final data = event.snapshot.value;
        if (data == null) return;

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
        } catch (_) {}
      },
    );
  }

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    // If Firebase has data, return it; otherwise fallback to realistic mock stream
    return _nodesController.stream.asBroadcastStream();
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    return watchAllNodes().map(
      (nodes) => nodes.where((n) => n.nodeId == nodeId).firstOrNull,
    );
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    return _mockFallback.watchTelemetryHistory(nodeId, days: days);
  }

  @override
  Stream<List<AlertModel>> watchAlerts() {
    return _alertsController.stream.asBroadcastStream();
  }

  @override
  Future<bool> triggerSirenTest(String pin) async {
    if (pin != '1234') return false;
    try {
      await _db.ref('commands/siren_test').set({
        'triggered_at': ServerValue.timestamp,
        'status': 'ACTIVE',
        'duration_sec': 10,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void triggerSimulation(String mode) {
    _mockFallback.triggerSimulation(mode);
  }

  @override
  void dispose() {
    _nodesSub?.cancel();
    _alertsSub?.cancel();
    _nodesController.close();
    _alertsController.close();
    _mockFallback.dispose();
  }
}
