import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';

/// Abstract Repository for IoT Sensor Nodes & Disaster Telemetry
abstract class NodeRepository {
  Stream<List<SensorNode>> watchAllNodes();
  Stream<SensorNode?> watchNode(int nodeId);
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7});
  Stream<List<AlertModel>> watchAlerts();
  Future<bool> triggerSirenTest(String pin);
  void triggerSimulation(String mode);
  void dispose();
}
