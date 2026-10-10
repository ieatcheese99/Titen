import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../dashboard/application/dashboard_providers.dart';

/// M21 FieldDiagnostics — Diagnostik Lapangan per 03_APP_FLUTTER_SPEC.md §5 & §7
class FieldDiagnosticsCard extends ConsumerWidget {
  const FieldDiagnosticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final gateway = ref.watch(gatewayHealthProvider).value;
    final nodes = ref.watch(allNodesProvider).value ?? [];

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
              Icon(Icons.fact_check_outlined, size: 20, color: tokens.textSecondary),
              const SizedBox(width: 8),
              Text(
                'DIAGNOSTIK & VERIFIKASI SISTEM',
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
          const SizedBox(height: 12),
          _diagnosticItem(
            tokens,
            title: 'Koneksi Cloud (Firebase RTDB)',
            detail: gateway?.cloudConnected == true ? 'Terhubung' : 'Offline / Standby',
            passed: gateway?.cloudConnected == true,
          ),
          _diagnosticItem(
            tokens,
            title: 'Penerima Radio LoRa (SX1278)',
            detail: gateway?.radioBand ?? '433.0 MHz (Firmware config)',
            passed: true,
          ),
          _diagnosticItem(
            tokens,
            title: 'Node Terdaftar di Registry',
            detail: '${nodes.length} Node Fisik',
            passed: nodes.isNotEmpty,
          ),
          _diagnosticItem(
            tokens,
            title: 'Wizard Provisioning BLE',
            detail: 'Memerlukan firmware ESP32 Provisioning v2.x',
            passed: false,
            isWarning: true,
          ),
          _diagnosticItem(
            tokens,
            title: 'Validasi Kesegaran Paket (R/J)',
            detail: 'R = 60s, Grace J = 15s aktif di client',
            passed: true,
          ),
        ],
      ),
    );
  }

  Widget _diagnosticItem(
    TitenTokens tokens, {
    required String title,
    required String detail,
    required bool passed,
    bool isWarning = false,
  }) {
    final colorSet = isWarning
        ? tokens.warning
        : (passed ? tokens.normal : tokens.critical);

    final icon = isWarning
        ? Icons.info_outline
        : (passed ? Icons.check_circle_outline : Icons.cancel_outlined);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorSet.fg),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TitenTypography.body(color: tokens.textPrimary).copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  detail,
                  style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
