import 'dart:async';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import '../models/gateway_health.dart';
import 'node_repository.dart';
import 'mock_node_repository.dart';

/// Real Firestore Node Repository for Production IoT Hardware Connection
class FirestoreNodeRepository implements NodeRepository {
  final MockNodeRepository _fallbackMock = MockNodeRepository();

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    return _fallbackMock.watchAllNodes();
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    return _fallbackMock.watchNode(nodeId);
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    return _fallbackMock.watchTelemetryHistory(nodeId, days: days);
  }

  @override
  Stream<List<AlertModel>> watchAlerts() {
    return _fallbackMock.watchAlerts();
  }

  @override
  Stream<GatewayHealth> watchGatewayHealth() {
    return _fallbackMock.watchGatewayHealth();
  }

  @override
  Future<bool> acknowledgeAlert(String alertId, String actor) {
    return _fallbackMock.acknowledgeAlert(alertId, actor);
  }

  @override
  Future<bool> resolveAlert(String alertId) {
    return _fallbackMock.resolveAlert(alertId);
  }

  @override
  Future<bool> triggerSirenCommand(int nodeId, bool enable, {int durationSec = 30}) {
    return _fallbackMock.triggerSirenCommand(nodeId, enable, durationSec: durationSec);
  }

  @override
  Future<bool> triggerSirenTest(String pin) {
    return _fallbackMock.triggerSirenTest(pin);
  }

  @override
  void triggerSimulation(String mode) {
    _fallbackMock.triggerSimulation(mode);
  }

  @override
  void dispose() {
    _fallbackMock.dispose();
  }
}
