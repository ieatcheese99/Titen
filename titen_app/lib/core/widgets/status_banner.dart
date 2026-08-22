import 'package:flutter/material.dart';
import '../../features/dashboard/data/models/zone_status.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class StatusBanner extends StatelessWidget {
  final ZoneStatus status;

  const StatusBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final statusColor = status.color;

    return Container(
      decoration: BoxDecoration(
        color: TitenColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TitenColors.outlineBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Status Accent Bar
            Container(
              width: 5,
              color: statusColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Circular Icon Box
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(status.level),
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status.title,
                            style: TitenTypography.titleLarge.copyWith(
                              color: status.level > 0 ? statusColor : TitenColors.textMain,
                              letterSpacing: 0.2,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            status.description,
                            style: TitenTypography.bodyMedium.copyWith(
                              color: TitenColors.textMuted,
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Last Updated Stamp
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'LAST UPDATED',
                          style: TitenTypography.dataLabel.copyWith(
                            fontSize: 9.5,
                            color: TitenColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Just now',
                          style: TitenTypography.bodyLarge.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TitenColors.textMain,
                          ),
                        ),
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
    switch (level) {
      case 0:
        return Icons.check_circle;
      case 1:
        return Icons.warning_amber_rounded;
      case 2:
        return Icons.notifications_active_rounded;
      case 3:
        return Icons.gpp_bad_rounded;
      default:
        return Icons.info_outline;
    }
  }
}
