import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/application/simulation_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ThreatSimulatorBar extends ConsumerWidget {
  const ThreatSimulatorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(activeSimulationModeProvider);
    final controller = ref.read(simulationControllerProvider);

    final modes = [
      {'key': 'aman', 'label': '🟢 Aman', 'color': TitenColors.statusAman},
      {'key': 'waspada_longsor', 'label': '🟡 Waspada Longsor', 'color': TitenColors.statusWaspada},
      {'key': 'waspada_karhutla', 'label': '🟧 Waspada Karhutla', 'color': TitenColors.statusSiaga},
      {'key': 'siaga', 'label': '🔔 Siaga', 'color': TitenColors.statusSiaga},
      {'key': 'awas_longsor', 'label': '🚨 AWAS LONGSOR', 'color': TitenColors.statusAwasLongsor},
      {'key': 'awas_karhutla', 'label': '🔥 AWAS KARHUTLA', 'color': TitenColors.statusAwasKarhutla},
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
                const Icon(Icons.science_outlined, size: 14, color: TitenColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  'SIMULASI BENCANA (MAGE 12 DEMO CONTROLLER):',
                  style: TitenTypography.dataLabel.copyWith(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => controller.setMode(m['key'] as String),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? color : TitenColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? color : TitenColors.outlineBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          m['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : TitenColors.textMain,
                          ),
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
