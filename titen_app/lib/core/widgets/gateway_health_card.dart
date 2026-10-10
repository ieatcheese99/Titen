import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/application/dashboard_providers.dart';

/// M04 GatewayHealth — Gateway status card per 03_APP_FLUTTER_SPEC.md §5
class GatewayHealthCard extends ConsumerWidget {
  const GatewayHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gatewayAsync = ref.watch(gatewayHealthProvider);
    final tokens = context.titenTokens;

    final gateway = gatewayAsync.value;
    final isOnline = gateway?.cloudConnected == true;
    final isLoraActive = gateway?.loraReceiverActive == true;

    final heartbeatStr = gateway?.lastHeartbeat != null
        ? DateFormat('HH:mm:ss').format(gateway!.lastHeartbeat!)
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.router_outlined,
                          size: 18,
                          color: tokens.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'KESEHATAN GATEWAY LORA',
                            style:
                                TitenTypography.technical(
                                  color: tokens.textSecondary,
                                ).copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline ? tokens.normal.bg : tokens.unknown.bg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isOnline
                            ? tokens.normal.border
                            : tokens.unknown.border,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isOnline ? 'CLOUD TERHUBUNG' : 'OFFLINE / UNKNOWN',
                      style: TitenTypography.technical(
                        color: isOnline ? tokens.normal.fg : tokens.unknown.fg,
                      ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final textScale = MediaQuery.textScalerOf(context).scale(13) / 13;
              final columns =
                  ((constraints.maxWidth + spacing) /
                          (130 * textScale + spacing))
                      .floor()
                      .clamp(1, 4);
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              final items = [
                _buildItem(
                  tokens,
                  label: 'Gateway ID',
                  value: gateway?.gatewayId ?? '—',
                ),
                _buildItem(
                  tokens,
                  label: 'LoRa Receiver',
                  value: isLoraActive ? 'Aktif' : 'Belum Teruji',
                  isAccent: isLoraActive,
                ),
                _buildItem(
                  tokens,
                  label: 'Radio Band',
                  value: gateway?.radioBand ?? '—',
                ),
                _buildItem(tokens, label: 'Heartbeat', value: heartbeatStr),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items
                    .map((item) => SizedBox(width: itemWidth, child: item))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    TitenTokens tokens, {
    required String label,
    required String value,
    bool isAccent = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TitenTypography.metadata(
            color: tokens.textMetadata,
          ).copyWith(fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TitenTypography.technical(
            color: isAccent ? tokens.normal.fg : tokens.textPrimary,
          ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
