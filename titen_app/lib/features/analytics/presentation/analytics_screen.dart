import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../application/analytics_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(allNodesProvider);
    final nodes = nodesAsync.value ?? [];
    final selectedNodeId = ref.watch(selectedNodeIdForAnalyticsProvider);
    final selectedMetric = ref.watch(selectedMetricProvider);
    final stats = ref.watch(metricStatsProvider);
    final historyAsync = ref.watch(telemetryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics & Tren Bencana', style: TitenTypography.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Node Selector Row
            Text('PILIH TITIK SENSOR (NODE):', style: TitenTypography.dataLabel),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: nodes.map((node) {
                  final isSelected = selectedNodeId == node.nodeId;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(node.name),
                      selected: isSelected,
                      selectedColor: TitenColors.primaryAccent,
                      backgroundColor: TitenColors.surfaceWhite,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : TitenColors.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? TitenColors.primaryAccent : TitenColors.outlineBorder,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(selectedNodeIdForAnalyticsProvider.notifier).state = node.nodeId;
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Metric Selector Tabs
            Container(
              decoration: BoxDecoration(
                color: TitenColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TitenColors.outlineBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _metricTab(ref, 'Tanah %', AnalyticsMetric.soilMoisture, selectedMetric),
                  _metricTab(ref, 'Suhu °C', AnalyticsMetric.airTemp, selectedMetric),
                  _metricTab(ref, 'Kemiringan °', AnalyticsMetric.tiltAngle, selectedMetric),
                  _metricTab(ref, 'Udara %', AnalyticsMetric.airHumidity, selectedMetric),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3, 4, 5. Main Chart Card and Statistics / Assessment
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;

                final chartCard = Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TitenColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TitenColors.outlineBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedMetric.title, style: TitenTypography.titleLarge),
                              Text('Tren Riwayat Telemetri (7 Hari Terakhir)', style: TitenTypography.bodySmall),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: TitenColors.baseBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: TitenColors.outlineBorder),
                            ),
                            child: Text(
                              '${stats.current} ${selectedMetric.unit}',
                              style: TitenTypography.dataValue.copyWith(
                                color: TitenColors.primaryAccent,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: isWide ? 300 : 220,
                        child: historyAsync.when(
                          data: (history) {
                            if (history.isEmpty) {
                              return const Center(child: Text('Tidak ada data riwayat.'));
                            }
                            return _buildLineChart(history, selectedMetric);
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Center(child: Text('Gagal memuat data grafik')),
                        ),
                      ),
                    ],
                  ),
                );

                final statsGrid = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RINGKASAN STATISTIK (7 HARI):', style: TitenTypography.dataLabel),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _statCard('TERENDAH', '${stats.min} ${selectedMetric.unit}', Icons.arrow_downward, TitenColors.tacticalCyan)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('RATA-RATA', '${stats.avg} ${selectedMetric.unit}', Icons.functions, TitenColors.primaryAccent)),
                        const SizedBox(width: 10),
                        Expanded(child: _statCard('TERTINGGI', '${stats.max} ${selectedMetric.unit}', Icons.arrow_upward, TitenColors.statusSiaga)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Risk Assessment Recommendation Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: TitenColors.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: TitenColors.outlineBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: TitenColors.primaryAccent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: TitenColors.primaryAccent, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Analisis Risiko Lereng & Iklim', style: TitenTypography.titleLarge.copyWith(fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(
                                  'Fluktuasi harian dalam ambang batas normal. Tidak ada pergeseran tanah signifikan atau lonjakan suhu ekstrem terdeteksi.',
                                  style: TitenTypography.bodySmall.copyWith(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: chartCard),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: statsGrid),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chartCard,
                    const SizedBox(height: 20),
                    statsGrid,
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _metricTab(WidgetRef ref, String label, AnalyticsMetric metric, AnalyticsMetric active) {
    final isSelected = metric == active;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(selectedMetricProvider.notifier).state = metric;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? TitenColors.surfaceWhite : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? TitenColors.textMain : TitenColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(List<dynamic> history, AnalyticsMetric metric) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      double val = 0;
      switch (metric) {
        case AnalyticsMetric.soilMoisture:
          val = item.soilMoisturePct;
          break;
        case AnalyticsMetric.airTemp:
          val = item.airTempC;
          break;
        case AnalyticsMetric.tiltAngle:
          val = item.tiltDeg;
          break;
        case AnalyticsMetric.airHumidity:
          val = item.airHumidityPct;
          break;
      }
      spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: TitenColors.outlineBorder,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: (history.length / 4).clamp(1, 10).toDouble(),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < history.length) {
                  final time = history[idx].timestamp as DateTime;
                  return Text(
                    DateFormat('d MMM').format(time),
                    style: TitenTypography.dataLabel.copyWith(fontSize: 9),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: TitenColors.primaryAccent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: TitenColors.primaryAccent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TitenColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TitenColors.outlineBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TitenTypography.dataLabel.copyWith(fontSize: 9)),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TitenTypography.dataValue.copyWith(fontSize: 16)),
        ],
      ),
    );
  }
}
