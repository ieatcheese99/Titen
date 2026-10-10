import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/theme/theme_provider.dart';

/// M24 Preferences — Theme, Haptics, and App Preferences per 03_APP_FLUTTER_SPEC.md §5
class PreferencesGroupCard extends ConsumerWidget {
  const PreferencesGroupCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final currentThemeMode = ref.watch(themeModeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, size: 20, color: tokens.textSecondary),
              const SizedBox(width: 8),
              Text(
                'PREFERENSI & TAMPILAN',
                style: TitenTypography.technical(color: tokens.textSecondary).copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 14),
          // Theme Selector
          Text('Mode Tema Antarmuka', style: TitenTypography.sectionTitle(color: tokens.textPrimary).copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text('Sistem'),
                icon: Icon(Icons.brightness_auto, size: 16),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text('Terang'),
                icon: Icon(Icons.light_mode_outlined, size: 16),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text('Gelap'),
                icon: Icon(Icons.dark_mode_outlined, size: 16),
              ),
            ],
            selected: {currentThemeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeModeProvider.notifier).state = newSelection.first;
            },
          ),
          const SizedBox(height: 16),
          // Haptics & Notifications Description
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Umpan Balik Haptik', style: TitenTypography.body(color: tokens.textPrimary)),
                  Text('Getaran pada konfirmasi ACK aktuasi relay', style: TitenTypography.metadata(color: tokens.textMetadata)),
                ],
              ),
              Switch(
                value: true,
                onChanged: (val) {},
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notifikasi Peringatan Kritis', style: TitenTypography.body(color: tokens.textPrimary)),
                  Text('FCM Push saat konsensus EWS Level 3', style: TitenTypography.metadata(color: tokens.textMetadata)),
                ],
              ),
              Switch(
                value: true,
                onChanged: (val) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
