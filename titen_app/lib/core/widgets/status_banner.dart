import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../features/dashboard/data/models/zone_status.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// M03 SyncBanner / Status Banner per 03_APP_FLUTTER_SPEC.md §5
class StatusBanner extends StatelessWidget {
  final ZoneStatus status;
  final VoidCallback? onRefresh;

  const StatusBanner({
    super.key,
    required this.status,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;

    // Resolve semantic token set based on status level
    final SemanticColorSet colorSet;
    if (status.level < 0) {
      colorSet = tokens.unknown;
    } else {
      switch (status.level) {
        case 0:
          colorSet = tokens.normal;
          break;
        case 1:
        case 2:
          colorSet = tokens.warning;
          break;
        case 3:
          colorSet = tokens.critical;
          break;
        default:
          colorSet = tokens.unknown;
      }
    }

    final formattedTime = DateFormat('HH:mm:ss').format(status.lastUpdated);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorSet.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Accent Bar (4dp)
            Container(
              width: 4,
              color: colorSet.fg,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Semantic Status Icon Container
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorSet.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colorSet.border, width: 1),
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(status.level),
                          color: colorSet.fg,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status.title,
                            style: TitenTypography.sectionTitle(
                              color: status.level > 0 ? colorSet.fg : tokens.textPrimary,
                            ).copyWith(
                              fontSize: 14,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.description,
                            style: TitenTypography.body(color: tokens.textSecondary).copyWith(
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Evaluation Time
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'EVALUASI',
                          style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          status.level < 0 ? '—' : formattedTime,
                          style: TitenTypography.technical(color: tokens.textPrimary).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (onRefresh != null) ...[
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: onRefresh,
                            child: Icon(Icons.refresh, size: 16, color: tokens.textMetadata),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(int level) {
    if (level < 0) return Icons.sync;
    switch (level) {
      case 0:
        return Icons.verified_user_outlined;
      case 1:
        return Icons.warning_amber_rounded;
      case 2:
        return Icons.notification_important_rounded;
      case 3:
        return Icons.dangerous_rounded;
      default:
        return Icons.help_outline;
    }
  }
}
