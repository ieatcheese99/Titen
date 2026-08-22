import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class BentoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color? accentColor;
  final bool isWarning;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    this.accentColor,
    this.isWarning = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? (isWarning ? TitenColors.statusAwasLongsor : TitenColors.tacticalCyan);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TitenColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWarning ? effectiveAccent.withOpacity(0.5) : TitenColors.outlineBorder,
            width: isWarning ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Label + Trend Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: effectiveAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label.toUpperCase(),
                      style: TitenTypography.dataLabel.copyWith(
                        fontSize: 11,
                        color: TitenColors.textMuted,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isWarning ? Icons.trending_up : Icons.trending_flat,
                  size: 16,
                  color: isWarning ? TitenColors.statusAwasLongsor : TitenColors.statusAman,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: TitenTypography.dataDisplay.copyWith(
                fontSize: 24,
                color: isWarning ? effectiveAccent : TitenColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle & Status
            Text(
              subtitle,
              style: TitenTypography.bodySmall.copyWith(
                color: isWarning ? effectiveAccent : TitenColors.textMuted,
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
