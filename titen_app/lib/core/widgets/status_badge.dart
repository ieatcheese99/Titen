import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/data/models/sensor_node.dart';

/// M07 StatusBadge — Semantic Status Badge per 03_APP_FLUTTER_SPEC.md §5
class StatusBadge extends StatelessWidget {
  final int? statusLevel;
  final int? hazardType;
  final FreshnessStatus? freshness;

  const StatusBadge({
    super.key,
    this.statusLevel,
    this.hazardType,
    this.freshness,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;

    final SemanticColorSet colorSet;
    final String label;
    final IconData icon;

    if (freshness != null) {
      switch (freshness!) {
        case FreshnessStatus.fresh:
          colorSet = tokens.normal;
          label = 'Fresh';
          icon = Icons.check_circle_outline;
          break;
        case FreshnessStatus.stale:
          colorSet = tokens.warning;
          label = 'Stale';
          icon = Icons.access_time;
          break;
        case FreshnessStatus.missing:
          colorSet = tokens.unknown;
          label = 'Missing';
          icon = Icons.signal_wifi_connected_no_internet_4;
          break;
        case FreshnessStatus.unknown:
          colorSet = tokens.unknown;
          label = 'Unknown';
          icon = Icons.help_outline;
          break;
      }
    } else if (statusLevel == null) {
      colorSet = tokens.unknown;
      label = 'Belum Dinilai';
      icon = Icons.help_outline;
    } else {
      switch (statusLevel!) {
        case 0:
          colorSet = tokens.normal;
          label = 'Aman';
          icon = Icons.verified_user_outlined;
          break;
        case 1:
          colorSet = tokens.warning;
          label = 'Waspada';
          icon = Icons.warning_amber_rounded;
          break;
        case 2:
          colorSet = tokens.warning;
          label = 'Siaga';
          icon = Icons.notification_important_outlined;
          break;
        case 3:
          colorSet = tokens.critical;
          label = hazardType == 2 ? 'AWAS KARHUTLA' : 'AWAS LONGSOR';
          icon = Icons.dangerous_outlined;
          break;
        default:
          colorSet = tokens.unknown;
          label = 'Belum Dinilai';
          icon = Icons.help_outline;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorSet.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorSet.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorSet.fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TitenTypography.technical(
                color: colorSet.fg,
              ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
