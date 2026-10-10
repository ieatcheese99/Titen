import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import '../models/gateway_health.dart';

/// Abstract Repository for IoT Sensor Nodes & Disaster Telemetry
/// Conforming to TITEN Repository Interface target (03_APP_FLUTTER_SPEC.md §10)
abstract class NodeRepository {
  Stream<List<SensorNode>> watchAllNodes();
  Stream<SensorNode?> watchNode(int nodeId);
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7});
  Stream<List<AlertModel>> watchAlerts();
  Stream<GatewayHealth> watchGatewayHealth();
  Future<bool> acknowledgeAlert(String alertId, String actor);
  Future<bool> resolveAlert(String alertId);
  Future<bool> triggerSirenCommand(int nodeId, bool enable, {int durationSec = 30});
  Future<bool> triggerSirenTest(String pin);
  void triggerSimulation(String mode);
  void dispose();
}
