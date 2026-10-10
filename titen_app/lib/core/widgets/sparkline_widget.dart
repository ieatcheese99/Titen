import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/data/models/telemetry_data.dart';

/// M11 Sparkline — Real sparkline conforming to 03_APP_FLUTTER_SPEC.md §4.3 & §5
class SparklineWidget extends StatelessWidget {
  final String title;
  final String unit;
  final List<TelemetryData> history;
  final num? Function(TelemetryData) valueExtractor;
  final Color? lineColor;

  const SparklineWidget({
    super.key,
    required this.title,
    required this.unit,
    required this.history,
    required this.valueExtractor,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;
    final strokeColor = lineColor ?? tokens.syncing.fg;

    // Filter valid non-null points
    final List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      final val = valueExtractor(history[i]);
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val.toDouble()));
      }
    }

    if (spots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfacePanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada riwayat pengukuran pada rentang ini.',
                  style: TitenTypography.metadata(color: tokens.textMetadata),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final marginY = (maxY - minY == 0) ? 1.0 : (maxY - minY) * 0.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 14),
              ),
              Text(
                'Min: ${minY.toStringAsFixed(1)} | Max: ${maxY.toStringAsFixed(1)} $unit',
                style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: LineChart(
              LineChartData(
                minY: minY - marginY,
                maxY: maxY + marginY,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit',
                          TitenTypography.technical(color: Colors.white).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY == 0) ? 1 : (maxY - minY) / 3,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: tokens.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(
                  show: false,
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false, // Strict: no synthetic smoothing per 03_APP_FLUTTER_SPEC.md §4.3
                    color: strokeColor,
                    barWidth: 1.8,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: spots.length <= 10,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 3,
                        color: strokeColor,
                        strokeWidth: 1,
                        strokeColor: tokens.surfacePanel,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false), // No decorative gradient
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
