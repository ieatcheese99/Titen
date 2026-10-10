import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../application/emergency_providers.dart';

/// M12 RelayToggle & M13 ActionConfirmSheet & M14 CommandProgress
/// Adhering to 03_APP_FLUTTER_SPEC.md §5 & §6
class RelayControlCard extends ConsumerWidget {
  final int nodeId;
  final String nodeName;

  const RelayControlCard({
    super.key,
    required this.nodeId,
    required this.nodeName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final isSirenActive = ref.watch(sirenActiveStateProvider);
    final commandStatus = ref.watch(commandStatusProvider);
    final lastMessage = ref.watch(lastCommandMessageProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSirenActive ? tokens.critical.border : tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.volume_up_outlined,
                    size: 20,
                    color: isSirenActive ? tokens.critical.fg : tokens.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'KENDALI RELAY SIRINE EWS',
                    style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSirenActive ? tokens.critical.bg : tokens.unknown.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSirenActive ? tokens.critical.border : tokens.unknown.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  isSirenActive ? 'RELAY ON' : 'RELAY STANDBY (OFF)',
                  style: TitenTypography.technical(
                    color: isSirenActive ? tokens.critical.fg : tokens.unknown.fg,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isSirenActive
                ? 'Output relay dikonfirmasi AKTIF pada $nodeName. Sirine dan strobe menyala.'
                : 'Relay sirine dalam kondisi siaga. Tekan tombol untuk mengusulkan aktuasi terkonfirmasi.',
            style: TitenTypography.body(color: tokens.textSecondary).copyWith(fontSize: 13),
          ),
          if (lastMessage != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Text(
                'Status: $lastMessage (${commandStatus.label})',
                style: TitenTypography.technical(color: tokens.textPrimary).copyWith(fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Action Buttons
          Row(
            children: [
              if (!isSirenActive)
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.critical.fg,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.warning_amber_rounded, size: 18),
                    label: Text('Aktifkan Sirine $nodeName'),
                    onPressed: () => _openConfirmationSheet(context, ref, enable: true),
                  ),
                )
              else
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 18),
                    label: Text('Matikan Sirine $nodeName'),
                    onPressed: () => _openConfirmationSheet(context, ref, enable: false),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _openConfirmationSheet(BuildContext context, WidgetRef ref, {required bool enable}) {
    final tokens = context.titenTokens;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // M13 ActionConfirmSheet Header
              Text(
                enable ? 'Konfirmasi Aktuasi Sirine EWS' : 'Konfirmasi Pematian Sirine',
                style: TitenTypography.sectionTitle(color: tokens.textPrimary),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enable ? tokens.critical.bg : tokens.unknown.bg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: enable ? tokens.critical.border : tokens.unknown.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  enable
                    ? 'PERINGATAN: Perintah ini akan menyalakan output relay hardware 120dB & Strobe pada $nodeName selama 30 detik untuk peringatan dini evakuasi warga.'
                    : 'Perintah ini akan menonaktifkan output relay sirine pada $nodeName.',
                  style: TitenTypography.body(
                    color: enable ? tokens.critical.fg : tokens.textSecondary,
                  ).copyWith(fontSize: 13),
                ),
              ),
              const SizedBox(height: 14),
              _metaRow('Target Perangkat', nodeName),
              _metaRow('Durasi Default', enable ? '30 Detik (Auto-cutoff)' : 'Seketika'),
              _metaRow('Jalur Transmisi', 'Gateway Downlink → LoRa (433MHz)'),
              _metaRow('Otoritas', 'Operator / Petugas Lapangan'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: enable ? tokens.critical.fg : tokens.actionPrimaryBg,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final controller = ref.read(emergencyControllerProvider);
                        await controller.executeSirenCommand(nodeId, enable, durationSec: 30);
                      },
                      child: Text(enable ? 'Kirim Perintah ON' : 'Kirim Perintah OFF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
