import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/application/simulation_controller.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ThreatSimulatorBar extends ConsumerWidget {
  const ThreatSimulatorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(dataSourceModeProvider);
    final activeMode = ref.watch(activeSimulationModeProvider);
    final controller = ref.read(simulationControllerProvider);
    final tokens = context.titenTokens;

    // Only active in DEMO mode per 03_APP_FLUTTER_SPEC.md §3.1 & §10
    if (!mode.isDemo) {
      return const SizedBox.shrink();
    }

    final modes = [
      {'key': 'aman', 'label': '🟢 Aman', 'color': tokens.normal.fg},
      {'key': 'waspada_longsor', 'label': '🟡 Waspada Longsor', 'color': tokens.warning.fg},
      {'key': 'awas_longsor', 'label': '🔴 AWAS LONGSOR', 'color': tokens.critical.fg},
      {'key': 'awas_karhutla', 'label': '🔥 AWAS KARHUTLA', 'color': tokens.critical.fg},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Icon(Icons.science_outlined, size: 14, color: tokens.textMetadata),
                const SizedBox(width: 6),
                Text(
                  'KONTROL SIMULATOR BAHAYA (DEMO LOMBA):',
                  style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: modes.map((m) {
                final isSelected = activeMode == m['key'];
                final color = m['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => controller.setMode(m['key'] as String),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color : tokens.surfacePanel,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? color : tokens.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        m['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : tokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
