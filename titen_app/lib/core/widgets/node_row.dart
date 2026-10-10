import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/data/models/sensor_node.dart';
import 'status_badge.dart';

/// M06 NodeRow — Quick inspection row per 03_APP_FLUTTER_SPEC.md §4.3 & §5
class NodeRow extends StatelessWidget {
  final SensorNode node;
  final VoidCallback onTap;

  const NodeRow({super.key, required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;
    final freshness = node.getFreshness();

    final timeStr = node.receivedAt != null || node.lastSeen != null
        ? DateFormat('HH:mm:ss').format(node.receivedAt ?? node.lastSeen!)
        : '—';

    final batteryStr = node.batteryPct != null ? '${node.batteryPct}%' : '—';
    final rssiStr = node.loraRssi != null ? '${node.loraRssi} dBm' : '—';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surfacePanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            // Node Identity Box
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Center(
                child: Text(
                  node.nodeId.toString().padLeft(2, '0'),
                  style: TitenTypography.valueCompact(
                    color: tokens.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name and Status Badges
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final textScale =
                      MediaQuery.textScalerOf(context).scale(14) / 14;
                  final isCompact = constraints.maxWidth < 500 * textScale;
                  final name = Text(
                    node.name,
                    style: TitenTypography.sectionTitle(
                      color: tokens.textPrimary,
                    ).copyWith(fontSize: 14),
                    maxLines: isCompact ? null : 1,
                    overflow: isCompact
                        ? TextOverflow.clip
                        : TextOverflow.ellipsis,
                  );
                  final badges = Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      StatusBadge(
                        statusLevel: node.lastStatusLevel,
                        hazardType: node.lastHazardType,
                      ),
                      StatusBadge(freshness: freshness),
                    ],
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCompact) ...[
                        SizedBox(width: constraints.maxWidth, child: name),
                        const SizedBox(height: 6),
                        badges,
                      ] else
                        Row(
                          children: [
                            Expanded(child: name),
                            const SizedBox(width: 8),
                            badges,
                          ],
                        ),
                      const SizedBox(height: 6),
                      // Keep each icon and measurement together as metadata wraps.
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _buildMetadataItem(
                            tokens,
                            Icons.access_time,
                            timeStr,
                            gap: 4,
                          ),
                          _buildMetadataItem(
                            tokens,
                            Icons.battery_std,
                            batteryStr,
                          ),
                          _buildMetadataItem(
                            tokens,
                            Icons.wifi_tethering,
                            rssiStr,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: tokens.textMetadata, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    TitenTokens tokens,
    IconData icon,
    String value, {
    double gap = 2,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: tokens.textMetadata),
        SizedBox(width: gap),
        Text(
          value,
          style: TitenTypography.technical(color: tokens.textMetadata),
        ),
      ],
    );
  }
}
