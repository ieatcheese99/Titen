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
    final tokens = context.titenTokens;
    final effectiveAccent = accentColor ?? (isWarning ? tokens.critical.fg : tokens.syncing.fg);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfacePanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWarning ? tokens.critical.border : tokens.borderSubtle,
            width: isWarning ? 1.5 : 1,
          ),
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
                        color: tokens.textMetadata,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isWarning ? Icons.trending_up : Icons.trending_flat,
                  size: 16,
                  color: isWarning ? tokens.critical.fg : tokens.normal.fg,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Value
            Text(
              value,
              style: TitenTypography.value(
                color: isWarning ? effectiveAccent : tokens.textPrimary,
              ).copyWith(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            // Subtitle & Status
            Text(
              subtitle,
              style: TitenTypography.metadata(
                color: isWarning ? effectiveAccent : tokens.textMetadata,
              ).copyWith(
                fontWeight: isWarning ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
