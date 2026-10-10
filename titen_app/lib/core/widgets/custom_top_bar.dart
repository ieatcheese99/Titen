import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'mode_chip.dart';

/// Top Bar conforming to 03_APP_FLUTTER_SPEC.md §4.2
/// Contains registry location, last sync time, ModeChip, and navigation shortcuts
/// without synthetic organization or avatar placeholders
class CustomTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? locationName;
  final VoidCallback? onSearchTap;

  const CustomTopBar({super.key, this.locationName, this.onSearchTap});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.titenTokens;
    final isCompact = MediaQuery.sizeOf(context).width < 520;
    final alertsAsync = ref.watch(alertsProvider);
    final activeAlertCount =
        alertsAsync.value?.where((a) => !a.resolved).length ?? 0;
    final nodes = ref.watch(allNodesProvider).value ?? [];
    final mode = ref.watch(dataSourceModeProvider);
    final receivedTimes =
        nodes
            .map((node) => node.receivedAt ?? node.lastSeen)
            .whereType<DateTime>()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    final syncTimeStr = receivedTimes.isEmpty
        ? 'Belum ada data'
        : '${DateFormat('HH:mm:ss').format(receivedTimes.first.toUtc().add(const Duration(hours: 7)))} WIB';
    final locatedCount = nodes.where((node) => node.hasValidCoordinates).length;
    final displayLocation =
        locationName ??
        (mode.isDemo
            ? 'Area simulasi · koordinat demo'
            : locatedCount == 0
            ? 'Lokasi node belum disetel'
            : '$locatedCount node berkoordinat');

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfacePanel,
        border: Border(
          bottom: BorderSide(color: tokens.borderSubtle, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // Left: Brand Logo & Registry Location
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'TITEN',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TitenTypography.sectionTitle(
                                  color: tokens.actionPrimaryBg,
                                ).copyWith(
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const ModeChip(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: tokens.textMetadata,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '$displayLocation · $syncTimeStr',
                            style:
                                TitenTypography.metadata(
                                  color: tokens.textSecondary,
                                ).copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Buttons: Alerts Badge & Settings Link
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search icon
                  if (!isCompact)
                    IconButton(
                      icon: Icon(
                        Icons.search,
                        size: 20,
                        color: tokens.textSecondary,
                      ),
                      tooltip: 'Cari Node',
                      onPressed: () {
                        if (onSearchTap != null) {
                          onSearchTap!();
                        } else {
                          context.go('/devices');
                        }
                      },
                    ),
                  // Alert Notification with Count Badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          size: 20,
                          color: tokens.textSecondary,
                        ),
                        tooltip: 'Peringatan Bencana',
                        onPressed: () => context.go('/alerts'),
                      ),
                      if (activeAlertCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: tokens.critical.fg,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '$activeAlertCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Settings / Tools button
                  if (!isCompact)
                    IconButton(
                      icon: Icon(
                        Icons.tune_outlined,
                        size: 20,
                        color: tokens.textSecondary,
                      ),
                      tooltip: 'Alat & Pengaturan',
                      onPressed: () => context.go('/tools/settings'),
                    ),
                  if (isCompact)
                    PopupMenuButton<String>(
                      tooltip: 'Menu aplikasi',
                      icon: Icon(Icons.more_horiz, color: tokens.textSecondary),
                      onSelected: (value) {
                        if (value == 'search') {
                          if (onSearchTap != null) {
                            onSearchTap!();
                          } else {
                            context.go('/devices');
                          }
                        } else {
                          context.go('/tools/settings');
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'search',
                          child: Text('Cari node'),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Text('Alat & pengaturan'),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
