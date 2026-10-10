import 'dart:async';
import 'dart:math';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import '../models/gateway_health.dart';
import '../../../../core/constants/hazard_constants.dart';
import 'node_repository.dart';

/// Interactive Mock Repository providing DEMO / Sintetis streams per 03_APP_FLUTTER_SPEC.md
class MockNodeRepository implements NodeRepository {
  final _nodesController = StreamController<List<SensorNode>>.broadcast();
  final _alertsController = StreamController<List<AlertModel>>.broadcast();
  final _gatewayController = StreamController<GatewayHealth>.broadcast();

  List<SensorNode> _currentNodes = [];
  List<AlertModel> _currentAlerts = [];
  Timer? _periodicTimer;

  MockNodeRepository() {
    _initInitialData();
    _periodicTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _applyLiveJitter();
    });
  }

  void _initInitialData() {
    final now = DateTime.now();
    _currentNodes = [
      SensorNode(
        nodeId: 1,
        name: 'Node 01 [DEMO/SINTETIS]',
        latitude: -6.9125,
        longitude: 107.6045,
        nodeType: 'landslide',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 94,
        loraRssi: -72,
        loraSnr: 9.8,
        lastSeen: now.subtract(const Duration(seconds: 30)),
        receivedAt: now.subtract(const Duration(seconds: 30)),
        lastTelemetry: TelemetryData(
          nodeId: 1,
          batteryPct: 94,
          tiltDeg: 1.2,
          soilMoisturePct: 42.5,
          airTempC: 24.8,
          airHumidityPct: 65.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(seconds: 30)),
          receivedAt: now.subtract(const Duration(seconds: 30)),
        ),
      ),
      SensorNode(
        nodeId: 2,
        name: 'Node 02 [DEMO/SINTETIS]',
        latitude: -6.9172,
        longitude: 107.6080,
        nodeType: 'combo',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 88,
        loraRssi: -81,
        loraSnr: 8.4,
        lastSeen: now.subtract(const Duration(minutes: 1)),
        receivedAt: now.subtract(const Duration(minutes: 1)),
        lastTelemetry: TelemetryData(
          nodeId: 2,
          batteryPct: 88,
          tiltDeg: 0.8,
          soilMoisturePct: 40.2,
          airTempC: 25.1,
          airHumidityPct: 62.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(minutes: 1)),
          receivedAt: now.subtract(const Duration(minutes: 1)),
        ),
      ),
      SensorNode(
        nodeId: 3,
        name: 'Node 03 [DEMO/SINTETIS]',
        latitude: -6.9100,
        longitude: 107.6150,
        nodeType: 'karhutla',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 98,
        loraRssi: -68,
        loraSnr: 10.2,
        lastSeen: now.subtract(const Duration(seconds: 45)),
        receivedAt: now.subtract(const Duration(seconds: 45)),
        lastTelemetry: TelemetryData(
          nodeId: 3,
          batteryPct: 98,
          tiltDeg: 0.2,
          soilMoisturePct: 35.0,
          airTempC: 26.5,
          airHumidityPct: 58.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(seconds: 45)),
          receivedAt: now.subtract(const Duration(seconds: 45)),
        ),
      ),
    ];

    _currentAlerts = [];
    _emit();
  }

  void _applyLiveJitter() {
    final random = Random();
    final now = DateTime.now();

    _currentNodes = _currentNodes.map((node) {
      final t = node.lastTelemetry;
      if (t == null) return node;

      final jitterTilt = max(0.0, (t.tiltDeg ?? 0) + (random.nextDouble() * 0.1 - 0.05));
      final jitterSoil = (t.soilMoisturePct ?? 40) + (random.nextDouble() * 0.4 - 0.2);
      final jitterTemp = (t.airTempC ?? 25) + (random.nextDouble() * 0.2 - 0.1);
      final jitterHum = (t.airHumidityPct ?? 60) + (random.nextDouble() * 0.4 - 0.2);

      return node.copyWith(
        lastSeen: now,
        receivedAt: now,
        lastTelemetry: t.copyWith(
          tiltDeg: double.parse(jitterTilt.toStringAsFixed(1)),
          soilMoisturePct: double.parse(jitterSoil.toStringAsFixed(1)),
          airTempC: double.parse(jitterTemp.toStringAsFixed(1)),
          airHumidityPct: double.parse(jitterHum.toStringAsFixed(1)),
          timestamp: now,
          receivedAt: now,
        ),
      );
    }).toList();

    _emit();
  }

  void _emit() {
    if (!_nodesController.isClosed) _nodesController.add(_currentNodes);
    if (!_alertsController.isClosed) _alertsController.add(_currentAlerts);
  }

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    return Stream.value(_currentNodes).concatWith([_nodesController.stream]);
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    return watchAllNodes().map(
      (nodes) => nodes.where((n) => n.nodeId == nodeId).firstOrNull,
    );
  }

  @override
  Stream<GatewayHealth> watchGatewayHealth() {
    return Stream.value(
      GatewayHealth(
        gatewayId: 'gateway_01',
        cloudConnected: true,
        loraReceiverActive: true,
        lastHeartbeat: DateTime.now(),
        firmwareVersion: 'v2.1.0-esp32',
        radioBand: '433.0 MHz',
        backlogCount: 0,
        status: 'online',
      ),
    ).concatWith([_gatewayController.stream]);
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    final List<TelemetryData> history = [];
    final now = DateTime.now();
    final random = Random(nodeId);

    for (int i = 0; i < 48; i++) {
      final time = now.subtract(Duration(minutes: i * 30));
      history.add(
        TelemetryData(
          nodeId: nodeId,
          batteryPct: max(40, 95 - (i ~/ 10)),
          tiltDeg: 1.0 + (random.nextDouble() * 0.5),
          soilMoisturePct: 40.0 + (random.nextDouble() * 6.0),
          airTempC: 24.0 + (random.nextDouble() * 3.0),
          airHumidityPct: 60.0 + (random.nextDouble() * 10.0),
          hazardType: 0,
          statusLevel: 0,
          timestamp: time,
          receivedAt: time,
        ),
      );
    }

    return Stream.value(history);
  }

  @override
  Stream<List<AlertModel>> watchAlerts() {
    return Stream.value(_currentAlerts).concatWith([_alertsController.stream]);
  }

  @override
  Future<bool> acknowledgeAlert(String alertId, String actor) async {
    _currentAlerts = _currentAlerts.map((a) {
      if (a.id == alertId) {
        return a.copyWith(
          acknowledged: true,
          acknowledgedAt: DateTime.now(),
          acknowledgedBy: actor,
        );
      }
      return a;
    }).toList();
    _emit();
    return true;
  }

  @override
  Future<bool> resolveAlert(String alertId) async {
    _currentAlerts = _currentAlerts.map((a) {
      if (a.id == alertId) {
        return a.copyWith(
          resolved: true,
          resolvedAt: DateTime.now(),
        );
      }
      return a;
    }).toList();
    _emit();
    return true;
  }

  @override
  Future<bool> triggerSirenCommand(int nodeId, bool enable, {int durationSec = 30}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return true;
  }

  @override
  Future<bool> triggerSirenTest(String pin) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return pin == HazardConstants.defaultSirenPin;
  }

  @override
  void triggerSimulation(String mode) {
    final now = DateTime.now();

    switch (mode) {
      case 'aman':
        _initInitialData();
        break;

      case 'waspada_longsor':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 1) {
            final t = n.lastTelemetry!;
            return n.copyWith(
              lastStatusLevel: 1,
              lastHazardType: 1,
              lastTelemetry: t.copyWith(
                tiltDeg: 3.2,
                soilMoisturePct: 74.0,
                statusLevel: 1,
                hazardType: 1,
                timestamp: now,
                receivedAt: now,
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [
          AlertModel(
            id: 'alert_waspada_01',
            hazardType: 1,
            statusLevel: 1,
            nodeIds: [1],
            confirmedAt: now,
            receivedAt: now,
            title: 'Waspada Potensi Longsor (Node 01)',
            description: 'Terjadi pergeseran kemiringan bertahap 3.2° dengan kelembapan 74%.',
          ),
        ];
        break;

      case 'awas_longsor':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 1) {
            final t = n.lastTelemetry!;
            return n.copyWith(
              lastStatusLevel: 3,
              lastHazardType: 1,
              lastTelemetry: t.copyWith(
                tiltDeg: 7.4,
                soilMoisturePct: 88.5,
                statusLevel: 3,
                hazardType: 1,
                timestamp: now,
                receivedAt: now,
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [
          AlertModel(
            id: 'alert_longsor_01',
            hazardType: 1,
            statusLevel: 3,
            nodeIds: [1],
            confirmedAt: now,
            receivedAt: now,
            latitude: -6.9125,
            longitude: 107.6045,
            resolved: false,
            title: '🔴 AWAS LONGSOR — Sektor Tebing Barat',
            description: 'Pergeseran lereng kemiringan 7.4° & kejenuhan tanah 88.5%. Sirine EWS terkonfirmasi aktif!',
          ),
        ];
        break;

      case 'awas_karhutla':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 3) {
            final t = n.lastTelemetry!;
            return n.copyWith(
              lastStatusLevel: 3,
              lastHazardType: 2,
              lastTelemetry: t.copyWith(
                airTempC: 48.2,
                airHumidityPct: 18.5,
                statusLevel: 3,
                hazardType: 2,
                timestamp: now,
                receivedAt: now,
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [
          AlertModel(
            id: 'alert_karhutla_01',
            hazardType: 2,
            statusLevel: 3,
            nodeIds: [3],
            confirmedAt: now,
            receivedAt: now,
            latitude: -6.9100,
            longitude: 107.6150,
            resolved: false,
            title: '🔥 AWAS KARHUTLA — Sektor Hutan Lindung',
            description: 'Suhu 48.2°C & kelembapan udara 18.5%. Titik api terdeteksi!',
          ),
        ];
        break;
    }

    _emit();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    _nodesController.close();
    _alertsController.close();
    _gatewayController.close();
  }
}

/// Helper extension for stream concat
extension StreamConcatExtension<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> other) async* {
    yield* this;
    for (final s in other) {
      yield* s;
    }
  }
}
