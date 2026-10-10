import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/application/dashboard_providers.dart';

/// M02 ModeChip — Data Provenance Chip per 03_APP_FLUTTER_SPEC.md §5
class ModeChip extends ConsumerWidget {
  const ModeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(dataSourceModeProvider);
    final tokens = context.titenTokens;

    final isLive = mode.isLive;
    final fg = isLive ? tokens.syncing.fg : tokens.warning.fg;
    final bg = isLive ? tokens.syncing.bg : tokens.warning.bg;
    final border = isLive ? tokens.syncing.border : tokens.warning.border;
    final label = isLive ? 'LIVE' : 'DEMO';

    return InkWell(
      onTap: () => _showModeExplanation(context, ref, isLive),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TitenTypography.technical(color: fg).copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModeExplanation(BuildContext context, WidgetRef ref, bool isLive) {
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
              Text('Mode Sumber Data', style: TitenTypography.sectionTitle(color: tokens.textPrimary)),
              const SizedBox(height: 10),
              Text(
                isLive
                    ? 'Mode LIVE: Menampilkan data telemetri aktual dari perangkat fisik dan gateway. Nilai kosong ditandai dengan "—" tanpa asumsi data palsu.'
                    : 'Mode DEMO: Menggunakan data sintetis / simulasi yang dirancang untuk pengujian alur lomba dan inspeksi protokol.',
                style: TitenTypography.body(color: tokens.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(dataSourceModeProvider.notifier).state =
                            isLive ? DataSourceMode.demo : DataSourceMode.live;
                        Navigator.of(ctx).pop();
                      },
                      child: Text(isLive ? 'Beralih ke DEMO' : 'Beralih ke LIVE'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
