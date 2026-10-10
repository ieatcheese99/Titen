import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/data/models/telemetry_data.dart';
import '../../dashboard/application/dashboard_providers.dart';

enum AnalyticsMetric { soilMoisture, airTemp, tiltAngle, airHumidity }

extension AnalyticsMetricExtension on AnalyticsMetric {
  String get title {
    switch (this) {
      case AnalyticsMetric.soilMoisture:
        return 'Kelembapan Tanah (%)';
      case AnalyticsMetric.airTemp:
        return 'Suhu Udara (°C)';
      case AnalyticsMetric.tiltAngle:
        return 'Kemiringan Tanah (°)';
      case AnalyticsMetric.airHumidity:
        return 'Kelembapan Udara (%)';
    }
  }

  String get unit {
    switch (this) {
      case AnalyticsMetric.soilMoisture:
        return '%';
      case AnalyticsMetric.airTemp:
        return '°C';
      case AnalyticsMetric.tiltAngle:
        return '°';
      case AnalyticsMetric.airHumidity:
        return '%';
    }
  }
}

final selectedNodeIdForAnalyticsProvider = StateProvider<int>((ref) => 1);
final selectedMetricProvider = StateProvider<AnalyticsMetric>(
  (ref) => AnalyticsMetric.soilMoisture,
);
final selectedTimeframeDaysProvider = StateProvider<int>((ref) => 7);

final telemetryHistoryProvider = StreamProvider<List<TelemetryData>>((ref) {
  final nodeId = ref.watch(selectedNodeIdForAnalyticsProvider);
  final days = ref.watch(selectedTimeframeDaysProvider);
  return watchReadyRepositoryStream(
    ref,
    (repo) => repo.watchTelemetryHistory(nodeId, days: days),
  );
});

class MetricStats {
  final double current;
  final double min;
  final double max;
  final double avg;

  MetricStats({
    required this.current,
    required this.min,
    required this.max,
    required this.avg,
  });

  factory MetricStats.empty() =>
      MetricStats(current: 0, min: 0, max: 0, avg: 0);
}

final metricStatsProvider = Provider<MetricStats>((ref) {
  final historyAsync = ref.watch(telemetryHistoryProvider);
  final metric = ref.watch(selectedMetricProvider);

  return historyAsync.when(
    data: (list) {
      if (list.isEmpty) return MetricStats.empty();

      final values = list
          .map((t) {
            switch (metric) {
              case AnalyticsMetric.soilMoisture:
                return t.soilMoisturePct;
              case AnalyticsMetric.airTemp:
                return t.airTempC;
              case AnalyticsMetric.tiltAngle:
                return t.tiltDeg;
              case AnalyticsMetric.airHumidity:
                return t.airHumidityPct;
            }
          })
          .whereType<double>()
          .toList();

      if (values.isEmpty) return MetricStats.empty();

      double minVal = values.first;
      double maxVal = values.first;
      double sum = 0;

      for (final v in values) {
        if (v < minVal) minVal = v;
        if (v > maxVal) maxVal = v;
        sum += v;
      }

      return MetricStats(
        current: values.first,
        min: double.parse(minVal.toStringAsFixed(1)),
        max: double.parse(maxVal.toStringAsFixed(1)),
        avg: double.parse((sum / values.length).toStringAsFixed(1)),
      );
    },
    loading: () => MetricStats.empty(),
    error: (_, __) => MetricStats.empty(),
  );
});
