import 'dart:async';
import 'dart:math';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import '../../../../core/constants/hazard_constants.dart';
import 'node_repository.dart';

/// Interactive Mock Repository providing realistic IoT streams & Demo State Controller
class MockNodeRepository implements NodeRepository {
  final _nodesController = StreamController<List<SensorNode>>.broadcast();
  final _alertsController = StreamController<List<AlertModel>>.broadcast();
  
  List<SensorNode> _currentNodes = [];
  List<AlertModel> _currentAlerts = [];
  String _currentMode = 'aman';
  Timer? _periodicTimer;

  MockNodeRepository() {
    _initInitialData();
    // Simulate slight live fluctuations
    _periodicTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _applyLiveJitter();
    });
  }

  void _initInitialData() {
    final now = DateTime.now();
    _currentNodes = [
      SensorNode(
        nodeId: 1,
        name: 'Node 01 - Tebing Barat (Curam)',
        latitude: -6.9125,
        longitude: 107.6045,
        nodeType: 'landslide',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 94,
        loraRssi: -72,
        loraSnr: 9.8,
        lastSeen: now.subtract(const Duration(minutes: 2)),
        lastTelemetry: TelemetryData(
          nodeId: 1,
          batteryPct: 94,
          tiltDeg: 1.2,
          soilMoisturePct: 42.5,
          airTempC: 24.8,
          airHumidityPct: 65.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(minutes: 2)),
        ),
      ),
      SensorNode(
        nodeId: 2,
        name: 'Node 02 - Lereng Selatan',
        latitude: -6.9172,
        longitude: 107.6080,
        nodeType: 'combo',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 88,
        loraRssi: -81,
        loraSnr: 8.4,
        lastSeen: now.subtract(const Duration(minutes: 5)),
        lastTelemetry: TelemetryData(
          nodeId: 2,
          batteryPct: 88,
          tiltDeg: 0.8,
          soilMoisturePct: 40.2,
          airTempC: 25.1,
          airHumidityPct: 62.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(minutes: 5)),
        ),
      ),
      SensorNode(
        nodeId: 3,
        name: 'Node 03 - Kawasan Hutan Lindung',
        latitude: -6.9100,
        longitude: 107.6150,
        nodeType: 'karhutla',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 98,
        loraRssi: -68,
        loraSnr: 10.2,
        lastSeen: now.subtract(const Duration(minutes: 1)),
        lastTelemetry: TelemetryData(
          nodeId: 3,
          batteryPct: 98,
          tiltDeg: 0.2,
          soilMoisturePct: 35.0,
          airTempC: 26.5,
          airHumidityPct: 58.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(minutes: 1)),
        ),
      ),
      SensorNode(
        nodeId: 4,
        name: 'Node 04 - Tebing Selatan (Perbatasan)',
        latitude: -6.9210,
        longitude: 107.6115,
        nodeType: 'combo',
        lastStatusLevel: 0,
        lastHazardType: 0,
        batteryPct: 76,
        loraRssi: -85,
        loraSnr: 7.1,
        lastSeen: now.subtract(const Duration(minutes: 4)),
        lastTelemetry: TelemetryData(
          nodeId: 4,
          batteryPct: 76,
          tiltDeg: 1.5,
          soilMoisturePct: 44.0,
          airTempC: 24.2,
          airHumidityPct: 67.0,
          hazardType: 0,
          statusLevel: 0,
          timestamp: now.subtract(const Duration(minutes: 4)),
        ),
      ),
    ];

    _currentAlerts = [];
    _emit();
  }

  void _applyLiveJitter() {
    final random = Random();
    if (_currentMode == 'aman') {
      _currentNodes = _currentNodes.map((n) {
        final t = n.lastTelemetry;
        if (t == null) return n;
        final jitterTemp = (random.nextDouble() * 0.4) - 0.2;
        final jitterSoil = (random.nextDouble() * 0.6) - 0.3;
        final newTele = t.copyWith(
          airTempC: double.parse((t.airTempC + jitterTemp).toStringAsFixed(1)),
          soilMoisturePct: double.parse((t.soilMoisturePct + jitterSoil).toStringAsFixed(1)),
          timestamp: DateTime.now(),
        );
        return n.copyWith(lastTelemetry: newTele, lastSeen: DateTime.now());
      }).toList();
      _emit();
    }
  }

  void _emit() {
    if (!_nodesController.isClosed) {
      _nodesController.add(List.unmodifiable(_currentNodes));
    }
    if (!_alertsController.isClosed) {
      _alertsController.add(List.unmodifiable(_currentAlerts));
    }
  }

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    // Immediate first item then stream updates
    return Stream.value(_currentNodes).concatWith([_nodesController.stream]);
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    return watchAllNodes().map(
      (nodes) => nodes.cast<SensorNode?>().firstWhere(
            (n) => n?.nodeId == nodeId,
            orElse: () => null,
          ),
    );
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    final now = DateTime.now();
    final random = Random(nodeId);
    final history = <TelemetryData>[];

    // Generate 7 days worth of historical hourly/daily data points
    final count = days * 4; // 4 readings per day
    for (int i = count; i >= 0; i--) {
      final time = now.subtract(Duration(hours: (i * 6)));
      
      double baseTilt = nodeId == 1 ? 1.5 : (nodeId == 4 ? 1.8 : 0.6);
      double baseSoil = 42.0;
      double baseTemp = 24.5;
      double baseHumid = 65.0;

      // Add day cycle curve
      final hourOfDay = time.hour;
      final tempCycle = sin((hourOfDay - 6) * pi / 12) * 4.0;
      final humidCycle = -sin((hourOfDay - 6) * pi / 12) * 15.0;

      history.add(
        TelemetryData(
          nodeId: nodeId,
          batteryPct: max(40, 100 - (i ~/ 8)),
          tiltDeg: double.parse((baseTilt + (random.nextDouble() * 0.4)).toStringAsFixed(1)),
          soilMoisturePct: double.parse((baseSoil + (random.nextDouble() * 5.0) - 2.5).toStringAsFixed(1)),
          airTempC: double.parse((baseTemp + tempCycle + (random.nextDouble() * 1.5)).toStringAsFixed(1)),
          airHumidityPct: double.parse((baseHumid + humidCycle + (random.nextDouble() * 3.0)).clamp(10.0, 95.0).toStringAsFixed(1)),
          hazardType: 0,
          statusLevel: 0,
          timestamp: time,
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
  Future<bool> triggerSirenTest(String pin) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return pin == HazardConstants.defaultSirenPin;
  }

  @override
  void triggerSimulation(String mode) {
    _currentMode = mode;
    final now = DateTime.now();

    switch (mode) {
      case 'aman':
        _initInitialData();
        break;

      case 'waspada_longsor':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 1 || n.nodeId == 4) {
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
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [];
        break;

      case 'waspada_karhutla':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 3 || n.nodeId == 2) {
            final t = n.lastTelemetry!;
            return n.copyWith(
              lastStatusLevel: 1,
              lastHazardType: 2,
              lastTelemetry: t.copyWith(
                airTempC: 41.5,
                airHumidityPct: 32.0,
                statusLevel: 1,
                hazardType: 2,
                timestamp: now,
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [];
        break;

      case 'siaga':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 1) {
            final t = n.lastTelemetry!;
            return n.copyWith(
              lastStatusLevel: 2,
              lastHazardType: 1,
              lastTelemetry: t.copyWith(
                tiltDeg: 4.8,
                soilMoisturePct: 79.5,
                statusLevel: 2,
                hazardType: 1,
                timestamp: now,
              ),
            );
          }
          return n;
        }).toList();
        _currentAlerts = [];
        break;

      case 'awas_longsor':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 1 || n.nodeId == 4) {
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
            nodeIds: [1, 4],
            confirmedAt: now,
            latitude: -6.9167,
            longitude: 107.6080,
            resolved: false,
            title: '🔴 AWAS LONGSOR — Konsensus Valid (Node 01 & 04)',
            description: 'Pergeseran lereng kemiringan 7.4° & kejenuhan tanah 88.5%. Sirine 120dB & LED Strobe aktif!',
          ),
        ];
        break;

      case 'awas_karhutla':
        _currentNodes = _currentNodes.map((n) {
          if (n.nodeId == 3 || n.nodeId == 2) {
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
            nodeIds: [2, 3],
            confirmedAt: now,
            latitude: -6.9136,
            longitude: 107.6115,
            resolved: false,
            title: '🔥 AWAS KARHUTLA — Konsensus Valid (Node 02 & 03)',
            description: 'Suhu ekstrem 48.2°C & kelembapan udara 18.5%. Titik api terdeteksi di Sektor Hutan Utara!',
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
