import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/application/dashboard_providers.dart';

/// M05 FleetSummary — Cakupan Node per 03_APP_FLUTTER_SPEC.md §5
class FleetSummaryCard extends ConsumerWidget {
  const FleetSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fleet = ref.watch(fleetSummaryProvider);
    final nodesAsync = ref.watch(allNodesProvider);
    final tokens = context.titenTokens;

    final isLoaded = nodesAsync.hasValue;
    final totalStr = isLoaded ? '${fleet.totalRegistered}' : '—';
    final freshStr = isLoaded ? '${fleet.freshCount}' : '—';
    final staleStr = isLoaded ? '${fleet.staleCount}' : '—';
    final missingStr = isLoaded ? '${fleet.missingCount}' : '—';
    final alertStr = isLoaded ? '${fleet.activeAlertCount}' : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  'RINGKASAN POPULASI NODE (REGISTRY)',
                  style: TitenTypography.technical(color: tokens.textSecondary)
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        fontSize: 12,
                      ),
                ),
                Text(
                  'Total: $totalStr Node',
                  style: TitenTypography.technical(
                    color: tokens.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Keep each counter readable when the available width or text scale changes.
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final textScale = MediaQuery.textScalerOf(context).scale(11) / 11;
              final columns =
                  ((constraints.maxWidth + spacing) /
                          (120 * textScale + spacing))
                      .floor()
                      .clamp(1, 4);
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final tiles = [
                _buildCountTile(
                  tokens,
                  label: 'Data Terbaru (Fresh)',
                  value: freshStr,
                  colorSet: tokens.normal,
                ),
                _buildCountTile(
                  tokens,
                  label: 'Terlambat (Stale)',
                  value: staleStr,
                  colorSet: tokens.warning,
                ),
                _buildCountTile(
                  tokens,
                  label: 'Hilang (Missing)',
                  value: missingStr,
                  colorSet: tokens.unknown,
                ),
                _buildCountTile(
                  tokens,
                  label: 'Alert Aktif',
                  value: alertStr,
                  colorSet: fleet.activeAlertCount > 0
                      ? tokens.critical
                      : tokens.normal,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: tiles
                    .map((tile) => SizedBox(width: tileWidth, child: tile))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCountTile(
    TitenTokens tokens, {
    required String label,
    required String value,
    required SemanticColorSet colorSet,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorSet.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorSet.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TitenTypography.value(
              color: colorSet.fg,
            ).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TitenTypography.metadata(
              color: colorSet.fg,
            ).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
