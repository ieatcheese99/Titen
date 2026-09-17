import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/sensor_node.dart';
import '../data/models/zone_status.dart';
import '../data/models/alert_model.dart';
import '../data/repositories/node_repository.dart';
import '../data/repositories/mock_node_repository.dart';
import '../data/repositories/firebase_node_repository.dart';

/// Mode Data Source: true = Firebase Realtime IoT, false = Offline Mock Simulator
final isFirebaseModeProvider = StateProvider<bool>((ref) => true);

/// Repository Provider (Singleton with dynamic switcher)
final nodeRepositoryProvider = Provider<NodeRepository>((ref) {
  final isFirebase = ref.watch(isFirebaseModeProvider);
  final repo = isFirebase ? FirebaseNodeRepository() : MockNodeRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

/// Stream of all IoT Sensor Nodes
final allNodesProvider = StreamProvider<List<SensorNode>>((ref) {
  final repo = ref.watch(nodeRepositoryProvider);
  return repo.watchAllNodes();
});

/// Single Node Provider family
final singleNodeProvider = StreamProvider.family<SensorNode?, int>((ref, nodeId) {
  final repo = ref.watch(nodeRepositoryProvider);
  return repo.watchNode(nodeId);
});

/// Stream of all active and historical alerts
final alertsProvider = StreamProvider<List<AlertModel>>((ref) {
  final repo = ref.watch(nodeRepositoryProvider);
  return repo.watchAlerts();
});

/// Overall Zone Status computed from all nodes & consensus alerts
final overallZoneStatusProvider = Provider<ZoneStatus>((ref) {
  final nodesAsync = ref.watch(allNodesProvider);
  final alertsAsync = ref.watch(alertsProvider);

  return nodesAsync.when(
    data: (nodes) {
      if (nodes.isEmpty) return ZoneStatus.safe();

      // Check if there are active consensus alerts first (Level 3 - Awas)
      final alerts = alertsAsync.value ?? [];
      final activeAlert = alerts.where((a) => !a.resolved).firstOrNull;
      if (activeAlert != null) {
        return activeAlert.hazardType == 2
            ? ZoneStatus.awasKarhutla()
            : ZoneStatus.awasLongsor();
      }

      // Check worst node status
      int maxLevel = 0;
      int dominantHazard = 0;
      for (final node in nodes) {
        if (node.lastStatusLevel > maxLevel) {
          maxLevel = node.lastStatusLevel;
          dominantHazard = node.lastHazardType;
        }
      }

      switch (maxLevel) {
        case 3:
          return dominantHazard == 2
              ? ZoneStatus.awasKarhutla()
              : ZoneStatus.awasLongsor();
        case 2:
          return ZoneStatus.siaga();
        case 1:
          return dominantHazard == 2
              ? ZoneStatus.waspadaKarhutla()
              : ZoneStatus.waspadaLongsor();
        default:
          return ZoneStatus.safe();
      }
    },
    loading: () => ZoneStatus.safe(),
    error: (_, __) => ZoneStatus.safe(),
  );
});

/// Summary telemetry aggregates for the Bento Grid on the Dashboard
class AggregateTelemetry {
  final double avgSoilMoisture;
  final double avgAirTemp;
  final double avgTiltDeg;
  final double avgAirHumidity;
  final int totalNodes;
  final int onlineNodes;
  final int anomalyCount;

  AggregateTelemetry({
    required this.avgSoilMoisture,
    required this.avgAirTemp,
    required this.avgTiltDeg,
    required this.avgAirHumidity,
    required this.totalNodes,
    required this.onlineNodes,
    required this.anomalyCount,
  });

  factory AggregateTelemetry.empty() {
    return AggregateTelemetry(
      avgSoilMoisture: 0,
      avgAirTemp: 0,
      avgTiltDeg: 0,
      avgAirHumidity: 0,
      totalNodes: 0,
      onlineNodes: 0,
      anomalyCount: 0,
    );
  }
}

final aggregateTelemetryProvider = Provider<AggregateTelemetry>((ref) {
  final nodesAsync = ref.watch(allNodesProvider);

  return nodesAsync.when(
    data: (nodes) {
      if (nodes.isEmpty) return AggregateTelemetry.empty();

      double sumSoil = 0;
      double sumTemp = 0;
      double sumTilt = 0;
      double sumHumid = 0;
      int teleCount = 0;
      int onlineCount = 0;
      int anomalies = 0;

      for (final n in nodes) {
        if (n.isOnline) onlineCount++;
        if (n.lastStatusLevel > 0) anomalies++;
        if (n.lastTelemetry != null) {
          sumSoil += n.lastTelemetry!.soilMoisturePct;
          sumTemp += n.lastTelemetry!.airTempC;
          sumTilt += n.lastTelemetry!.tiltDeg;
          sumHumid += n.lastTelemetry!.airHumidityPct;
          teleCount++;
        }
      }

      if (teleCount == 0) return AggregateTelemetry.empty();

      return AggregateTelemetry(
        avgSoilMoisture: double.parse((sumSoil / teleCount).toStringAsFixed(1)),
        avgAirTemp: double.parse((sumTemp / teleCount).toStringAsFixed(1)),
        avgTiltDeg: double.parse((sumTilt / teleCount).toStringAsFixed(1)),
        avgAirHumidity: double.parse((sumHumid / teleCount).toStringAsFixed(1)),
        totalNodes: nodes.length,
        onlineNodes: onlineCount,
        anomalyCount: anomalies,
      );
    },
    loading: () => AggregateTelemetry.empty(),
    error: (_, __) => AggregateTelemetry.empty(),
  );
});
