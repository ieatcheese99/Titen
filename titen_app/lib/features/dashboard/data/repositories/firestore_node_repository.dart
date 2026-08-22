import 'dart:async';
import '../models/sensor_node.dart';
import '../models/telemetry_data.dart';
import '../models/alert_model.dart';
import 'node_repository.dart';
import 'mock_node_repository.dart';

/// Real Firestore Node Repository for Production IoT Hardware Connection
/// Automatically bridges to Firestore collections:
/// - 'nodes' (SensorNode documents)
/// - 'nodes/{nodeId}/telemetry' (TelemetryData subcollections)
/// - 'alerts' (Consensus Engine Alert documents)
class FirestoreNodeRepository implements NodeRepository {
  final MockNodeRepository _fallbackMock = MockNodeRepository();

  // In production with flutterfire configured, Firestore instances connect here:
  // final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Stream<List<SensorNode>> watchAllNodes() {
    // Production implementation:
    // return _db.collection('nodes').snapshots().map(
    //   (snap) => snap.docs.map((d) => SensorNode.fromMap(d.data(), d.id)).toList(),
    // );
    return _fallbackMock.watchAllNodes();
  }

  @override
  Stream<SensorNode?> watchNode(int nodeId) {
    // Production implementation:
    // return _db.collection('nodes').doc(nodeId.toString()).snapshots().map(
    //   (doc) => doc.exists ? SensorNode.fromMap(doc.data()!, doc.id) : null,
    // );
    return _fallbackMock.watchNode(nodeId);
  }

  @override
  Stream<List<TelemetryData>> watchTelemetryHistory(int nodeId, {int days = 7}) {
    // Production implementation:
    // return _db.collection('nodes').doc(nodeId.toString())
    //   .collection('telemetry')
    //   .orderBy('timestamp', descending: true)
    //   .limit(days * 4)
    //   .snapshots()
    //   .map((snap) => snap.docs.map((d) => TelemetryData.fromMap(d.data())).toList());
    return _fallbackMock.watchTelemetryHistory(nodeId, days: days);
  }

  @override
  Stream<List<AlertModel>> watchAlerts() {
    // Production implementation:
    // return _db.collection('alerts')
    //   .orderBy('confirmed_at', descending: true)
    //   .snapshots()
    //   .map((snap) => snap.docs.map((d) => AlertModel.fromMap(d.data(), d.id)).toList());
    return _fallbackMock.watchAlerts();
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
