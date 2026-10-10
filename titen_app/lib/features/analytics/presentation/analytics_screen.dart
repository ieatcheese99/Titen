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
    final tokens = context.titenTokens;
    final nodesAsync = ref.watch(allNodesProvider);
    final nodes = nodesAsync.value ?? [];
    final selectedNodeId = ref.watch(selectedNodeIdForAnalyticsProvider);
    final selectedMetric = ref.watch(selectedMetricProvider);
    final stats = ref.watch(metricStatsProvider);
    final historyAsync = ref.watch(telemetryHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analitik & Tren Telemetri',
          style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Node Selector Row
            Text(
              'PILIH TITIK SENSOR (NODE):',
              style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                fontSize: 12,
              ),
            ),
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
                      selectedColor: tokens.actionPrimaryBg,
                      backgroundColor: tokens.surfacePanel,
                      labelStyle: TextStyle(
                        color: isSelected ? tokens.actionPrimaryFg : tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected ? tokens.actionPrimaryBg : tokens.borderControl,
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
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _metricTab(tokens, ref, 'Tanah %', AnalyticsMetric.soilMoisture, selectedMetric),
                  _metricTab(tokens, ref, 'Suhu °C', AnalyticsMetric.airTemp, selectedMetric),
                  _metricTab(tokens, ref, 'Kemiringan °', AnalyticsMetric.tiltAngle, selectedMetric),
                  _metricTab(tokens, ref, 'Udara %', AnalyticsMetric.airHumidity, selectedMetric),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. Main Chart Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: tokens.surfacePanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tokens.borderSubtle),
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
                          Text(
                            selectedMetric.title,
                            style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Histori pengamatan 7 hari terakhir',
                            style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      Text(
                        '${stats.current} ${selectedMetric.unit}',
                        style: TitenTypography.value(color: tokens.actionPrimaryBg).copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 220,
                    child: historyAsync.when(
                      data: (history) {
                        if (history.isEmpty) {
                          return Center(
                            child: Text(
                              'Belum ada data historis.',
                              style: TitenTypography.metadata(color: tokens.textMetadata),
                            ),
                          );
                        }
                        return _buildLineChart(tokens, history, selectedMetric);
                      },
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Statistics Summary Grid
            Row(
              children: [
                Expanded(
                  child: _statCard(
                    tokens,
                    'TERENDAH (MIN)',
                    '${stats.min} ${selectedMetric.unit}',
                    Icons.arrow_downward,
                    tokens.syncing.fg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    tokens,
                    'TERTINGGI (MAX)',
                    '${stats.max} ${selectedMetric.unit}',
                    Icons.arrow_upward,
                    tokens.critical.fg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statCard(
                    tokens,
                    'RATA-RATA',
                    '${stats.avg} ${selectedMetric.unit}',
                    Icons.calculate_outlined,
                    tokens.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _metricTab(
    TitenTokens tokens,
    WidgetRef ref,
    String label,
    AnalyticsMetric metric,
    AnalyticsMetric selected,
  ) {
    final isSelected = metric == selected;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(selectedMetricProvider.notifier).state = metric;
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? tokens.surfacePanel : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: tokens.borderSubtle) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? tokens.textPrimary : tokens.textMetadata,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChart(TitenTokens tokens, List<dynamic> history, AnalyticsMetric metric) {
    final spots = <FlSpot>[];
    for (int i = 0; i < history.length; i++) {
      final item = history[i];
      double val = 0;
      switch (metric) {
        case AnalyticsMetric.soilMoisture:
          val = (item.soilMoisturePct as num?)?.toDouble() ?? 0;
          break;
        case AnalyticsMetric.airTemp:
          val = (item.airTempC as num?)?.toDouble() ?? 0;
          break;
        case AnalyticsMetric.tiltAngle:
          val = (item.tiltDeg as num?)?.toDouble() ?? 0;
          break;
        case AnalyticsMetric.airHumidity:
          val = (item.airHumidityPct as num?)?.toDouble() ?? 0;
          break;
      }
      spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.isEmpty) {
      return Center(
        child: Text('Tidak ada sampel numerik valid.', style: TextStyle(color: tokens.textMetadata)),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 10,
          getDrawingHorizontalLine: (value) => FlLine(
            color: tokens.borderSubtle,
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
                  final time = history[idx].timestamp as DateTime?;
                  if (time != null) {
                    return Text(
                      DateFormat('d MMM').format(time),
                      style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 10),
                    );
                  }
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
            isCurved: false, // Strict: no synthetic smoothing
            color: tokens.syncing.fg,
            barWidth: 2.0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 15,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 2.5,
                color: tokens.syncing.fg,
                strokeWidth: 1,
                strokeColor: tokens.surfacePanel,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _statCard(TitenTokens tokens, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 9.5),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TitenTypography.technical(color: tokens.textPrimary).copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
