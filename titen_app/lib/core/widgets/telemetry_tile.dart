import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// M10 TelemetryTile — Sensor Measurement Tile per 03_APP_FLUTTER_SPEC.md §5
class TelemetryTile extends StatelessWidget {
  final String label;
  final num? value;
  final String unit;
  final String? thresholdDesc;
  final IconData icon;
  final bool isAnomalous;
  final String? quality;
  final VoidCallback? onTap;

  const TelemetryTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.thresholdDesc,
    required this.icon,
    this.isAnomalous = false,
    this.quality,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.titenTokens;

    final hasValue = value != null;
    final valueStr = hasValue
        ? (value is double ? (value as double).toStringAsFixed(1) : value.toString())
        : '—';

    final colorSet = isAnomalous
        ? tokens.critical
        : (hasValue ? tokens.normal : tokens.unknown);

    return InkWell(
      onTap: onTap ?? () => _showDetailSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tokens.surfacePanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAnomalous ? tokens.critical.border : tokens.borderSubtle,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TitenTypography.metadata(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorSet.bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 18, color: colorSet.fg),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  valueStr,
                  style: TitenTypography.value(
                    color: isAnomalous ? tokens.critical.fg : tokens.textPrimary,
                  ).copyWith(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                if (hasValue && unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            if (thresholdDesc != null)
              Text(
                thresholdDesc!,
                style: TitenTypography.metadata(
                  color: isAnomalous ? tokens.critical.fg : tokens.textMetadata,
                ).copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else if (!hasValue)
              Text(
                'Belum ada pengukuran terverifikasi',
                style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context) {
    final tokens = context.titenTokens;

    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detail Pengukuran: $label', style: TitenTypography.sectionTitle(color: tokens.textPrimary)),
              const SizedBox(height: 12),
              _sheetRow('Nilai Terbaca', value != null ? '$value $unit' : '— (Tidak tersedia pada payload)'),
              _sheetRow('Status Sensor', quality ?? (value != null ? 'Valid' : 'Unavailable / No packet')),
              if (thresholdDesc != null) _sheetRow('Ambang Batas', thresholdDesc!),
              _sheetRow('Sumber Data', 'Paket Telemetri Fisik LoRa'),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sheetRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(val, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
