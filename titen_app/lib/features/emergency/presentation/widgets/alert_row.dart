import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../dashboard/data/models/alert_model.dart';
import '../../application/emergency_providers.dart';

/// M15 AlertRow & M16 AlertEvidence per 03_APP_FLUTTER_SPEC.md §5 & §8
class AlertItemCard extends ConsumerWidget {
  final AlertModel alert;

  const AlertItemCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;

    final colorSet = alert.statusLevel == 3
        ? tokens.critical
        : (alert.statusLevel == 2 ? tokens.warning : tokens.normal);

    final timeStr = alert.receivedAt != null || alert.confirmedAt != null
        ? DateFormat('dd MMM, HH:mm:ss').format(alert.receivedAt ?? alert.confirmedAt!)
        : '—';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Semantic Rule 3dp
            Container(width: 4, color: colorSet.fg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorSet.bg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colorSet.border, width: 1),
                              ),
                              child: Text(
                                alert.lifecycle.label.toUpperCase(),
                                style: TitenTypography.technical(color: colorSet.fg).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Node: ${alert.nodeIds.map((id) => "0$id").join(", ")}',
                              style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          timeStr,
                          style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      alert.title,
                      style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.description,
                      style: TitenTypography.body(color: tokens.textSecondary).copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Actions: Acknowledge & Evidence Sheet
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showEvidenceSheet(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: const Size(40, 36),
                          ),
                          child: const Text('Lihat Bukti', style: TextStyle(fontSize: 12)),
                        ),
                        if (!alert.acknowledged && !alert.resolved) ...[
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () async {
                              final controller = ref.read(emergencyControllerProvider);
                              await controller.acknowledgeAlert(alert.id, 'Petugas Mobile');
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: tokens.actionPrimaryBg,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(40, 36),
                            ),
                            child: const Text('Akui (Acknowledge)', style: TextStyle(fontSize: 12)),
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

  void _showEvidenceSheet(BuildContext context) {
    final tokens = context.titenTokens;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bukti Telemetri Alert (Evidence)', style: TitenTypography.sectionTitle(color: tokens.textPrimary)),
              const SizedBox(height: 12),
              _item('ID Peringatan', alert.id),
              _item('Tingkat Bahaya', alert.statusLevel == 3 ? 'Awas (Level 3)' : 'Waspada / Siaga'),
              _item('Jenis Bahaya', alert.hazardName),
              _item('Node Terlibat', alert.nodeIds.map((id) => 'Node 0$id').join(', ')),
              _item('Waktu Diterima', alert.receivedAt?.toIso8601String() ?? '—'),
              _item('Status Diakui', alert.acknowledged ? 'Sudah (${alert.acknowledgedBy ?? "Petugas"})' : 'Belum diakui'),
              if (alert.resolved) _item('Status Selesai', 'Insiden terselesaikan'),
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

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
