import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../../features/dashboard/application/dashboard_providers.dart';

/// M22 CacheStatus — Cache provenance & sync age footer per 03_APP_FLUTTER_SPEC.md §5 & §9
class CacheStatusFooter extends ConsumerWidget {
  const CacheStatusFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final mode = ref.watch(dataSourceModeProvider);
    final nowStr = DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.storage_outlined, size: 14, color: tokens.textMetadata),
              const SizedBox(width: 6),
              Text(
                mode.isLive ? 'SUMBER: LIVE PIPELINE' : 'SUMBER: DEMO FIXTURE',
                style: TitenTypography.technical(color: tokens.textMetadata).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            '$nowStr WIB',
            style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
