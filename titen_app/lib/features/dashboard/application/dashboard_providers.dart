import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firebase_bootstrap.dart';
import '../data/models/sensor_node.dart';
import '../data/models/zone_status.dart';
import '../data/models/alert_model.dart';
import '../data/models/gateway_health.dart';
import '../data/repositories/node_repository.dart';
import '../data/repositories/mock_node_repository.dart';
import '../data/repositories/firebase_node_repository.dart';

/// Data Source Mode per 03_APP_FLUTTER_SPEC.md §3.1
enum DataSourceMode {
  live,
  demo;

  bool get isLive => this == DataSourceMode.live;
  bool get isDemo => this == DataSourceMode.demo;
}

/// Provider for Data Source Mode: defaults to Live
final dataSourceModeProvider = StateProvider<DataSourceMode>(
  (ref) => DataSourceMode.live,
);

/// Backward compatibility provider for isFirebaseModeProvider
final isFirebaseModeProvider = StateProvider<bool>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  return mode.isLive;
});

/// Repository Provider (Singleton with dynamic switcher)
final nodeRepositoryProvider = Provider<NodeRepository>((ref) {
  final mode = ref.watch(dataSourceModeProvider);
  final repo = mode.isLive ? FirebaseNodeRepository() : MockNodeRepository();
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

/// Subscribe only after Live initialization succeeds; DEMO needs no Firebase.
/// asyncExpand also prevents creating a Live repository if the pending stream
/// is cancelled, for example when the user switches to DEMO during startup.
Stream<T> watchReadyRepositoryStream<T>(
  Ref ref,
  Stream<T> Function(NodeRepository repository) watch,
) {
  final mode = ref.watch(dataSourceModeProvider);
  if (mode.isDemo) {
    return watch(ref.watch(nodeRepositoryProvider));
  }

  final bootstrap = ref.watch(firebaseBootstrapProvider.future);
  return Stream.fromFuture(
    bootstrap,
  ).asyncExpand((_) => watch(ref.read(nodeRepositoryProvider)));
}

/// Stream of all IoT Sensor Nodes
final allNodesProvider = StreamProvider<List<SensorNode>>((ref) {
  return watchReadyRepositoryStream(ref, (repo) => repo.watchAllNodes());
});

/// Single Node Provider family
final singleNodeProvider = StreamProvider.family<SensorNode?, int>((
  ref,
  nodeId,
) {
  return watchReadyRepositoryStream(ref, (repo) => repo.watchNode(nodeId));
});

/// Stream of all active and historical alerts
final alertsProvider = StreamProvider<List<AlertModel>>((ref) {
  return watchReadyRepositoryStream(ref, (repo) => repo.watchAlerts());
});

/// Stream of Gateway Health
final gatewayHealthProvider = StreamProvider<GatewayHealth>((ref) {
  return watchReadyRepositoryStream(ref, (repo) => repo.watchGatewayHealth());
});

/// Overall Zone Status computed with strict honesty (03_APP_FLUTTER_SPEC.md §3.1)
/// Never defaults to Aman when loading, empty, or unassessed!
final overallZoneStatusProvider = Provider<ZoneStatus>((ref) {
  final nodesAsync = ref.watch(allNodesProvider);
  final alertsAsync = ref.watch(alertsProvider);

  return nodesAsync.when(
    data: (nodes) {
      if (nodes.isEmpty) {
        return ZoneStatus.unknown('Belum ada data sensor dari node fisik.');
      }

      // Check if there are active alerts first
      final alerts = alertsAsync.value ?? [];
      final activeAlert = alerts.where((a) => !a.resolved).firstOrNull;
      if (activeAlert != null) {
        if (activeAlert.statusLevel == 3) {
          return activeAlert.hazardType == 2
              ? ZoneStatus.awasKarhutla()
              : ZoneStatus.awasLongsor();
        } else if (activeAlert.statusLevel == 2) {
          return ZoneStatus.siaga();
        } else if (activeAlert.statusLevel == 1) {
          return activeAlert.hazardType == 2
              ? ZoneStatus.waspadaKarhutla()
              : ZoneStatus.waspadaLongsor();
        }
      }

      // Check worst node status among fresh nodes
      final freshNodes = nodes
          .where((n) => n.getFreshness() == FreshnessStatus.fresh)
          .toList();
      if (freshNodes.isEmpty) {
        return ZoneStatus.unknown(
          'Semua data terlambat / tidak fresh. Belum dapat dipastikan aman.',
        );
      }

      int maxLevel = 0;
      int dominantHazard = 0;
      for (final node in freshNodes) {
        final level = node.lastStatusLevel ?? 0;
        if (level > maxLevel) {
          maxLevel = level;
          dominantHazard = node.lastHazardType ?? 0;
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
    loading: () => ZoneStatus.loading(),
    error: (err, _) => ZoneStatus.unknown('Gagal membaca data: $err'),
  );
});

/// Fleet Summary data model conforming to Component M05 (03_APP_FLUTTER_SPEC.md §5)
class FleetSummaryData {
  final int totalRegistered;
  final int freshCount;
  final int staleCount;
  final int missingCount;
  final int unknownCount;
  final int activeAlertCount;

  const FleetSummaryData({
    required this.totalRegistered,
    required this.freshCount,
    required this.staleCount,
    required this.missingCount,
    required this.unknownCount,
    required this.activeAlertCount,
  });

  factory FleetSummaryData.empty() => const FleetSummaryData(
    totalRegistered: 0,
    freshCount: 0,
    staleCount: 0,
    missingCount: 0,
    unknownCount: 0,
    activeAlertCount: 0,
  );
}

final fleetSummaryProvider = Provider<FleetSummaryData>((ref) {
  final nodesAsync = ref.watch(allNodesProvider);
  final alertsAsync = ref.watch(alertsProvider);

  final nodes = nodesAsync.value ?? [];
  final alerts = alertsAsync.value ?? [];

  int fresh = 0;
  int stale = 0;
  int missing = 0;
  int unknown = 0;

  for (final node in nodes) {
    switch (node.getFreshness()) {
      case FreshnessStatus.fresh:
        fresh++;
        break;
      case FreshnessStatus.stale:
        stale++;
        break;
      case FreshnessStatus.missing:
        missing++;
        break;
      case FreshnessStatus.unknown:
        unknown++;
        break;
    }
  }

  final activeAlerts = alerts.where((a) => !a.resolved).length;

  return FleetSummaryData(
    totalRegistered: nodes.length,
    freshCount: fresh,
    staleCount: stale,
    missingCount: missing,
    unknownCount: unknown,
    activeAlertCount: activeAlerts,
  );
});

/// Backward-compatible AggregateTelemetry
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
  final fleet = ref.watch(fleetSummaryProvider);
  final nodes = ref.watch(allNodesProvider).value ?? [];

  int anomalies = 0;
  for (final n in nodes) {
    if ((n.lastStatusLevel ?? 0) > 0) anomalies++;
  }

  return AggregateTelemetry(
    avgSoilMoisture: 0,
    avgAirTemp: 0,
    avgTiltDeg: 0,
    avgAirHumidity: 0,
    totalNodes: fleet.totalRegistered,
    onlineNodes: fleet.freshCount,
    anomalyCount: anomalies,
  );
});
