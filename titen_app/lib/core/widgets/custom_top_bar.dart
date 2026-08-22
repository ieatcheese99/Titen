import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class CustomTopBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final ValueChanged<String>? onSearch;

  const CustomTopBar({
    super.key,
    this.title = 'Disaster Monitoring Overview',
    this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final hasActiveAlert = alertsAsync.value?.any((a) => !a.resolved) ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        color: TitenColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: TitenColors.outlineBorder)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Left Title / Branding
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: TitenColors.primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.landscape_rounded,
                          size: 16,
                          color: TitenColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TITEN System',
                        style: TitenTypography.titleLarge.copyWith(
                          color: TitenColors.primaryAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: TitenTypography.headlineMedium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Search pill / icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: TitenColors.baseBackground,
                shape: BoxShape.circle,
                border: Border.all(color: TitenColors.outlineBorder),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.search, size: 18, color: TitenColors.textMuted),
                onPressed: () {
                  // Show search sheet or quick node search
                  _showSearchDialog(context, ref);
                },
              ),
            ),
            const SizedBox(width: 8),

            // Notification Bell with Badge
            Stack(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: TitenColors.baseBackground,
                    shape: BoxShape.circle,
                    border: Border.all(color: TitenColors.outlineBorder),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.notifications_outlined, size: 19, color: TitenColors.textMain),
                    onPressed: () {
                      _showNotificationsDialog(context, ref);
                    },
                  ),
                ),
                if (hasActiveAlert)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: TitenColors.statusAwasLongsor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),

            // User Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: TitenColors.primaryAccent,
                shape: BoxShape.circle,
                border: Border.all(color: TitenColors.outlineBorder, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'TR',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.read(allNodesProvider);
    final nodes = nodesAsync.value ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TitenColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cari Sensor & Lokasi',
                style: TitenTypography.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ketik nama node, mis. Tebing, Hutan...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: nodes.length,
                  itemBuilder: (ctx, i) {
                    final n = nodes[i];
                    return ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.sensors,
                        color: n.lastStatusLevel == 0
                            ? TitenColors.statusAman
                            : TitenColors.statusAwasLongsor,
                      ),
                      title: Text(n.name, style: TitenTypography.bodyLarge),
                      subtitle: Text('Status: ${n.statusText} • Baterai ${n.batteryPct}%'),
                      onTap: () {
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsDialog(BuildContext context, WidgetRef ref) {
    final alerts = ref.read(alertsProvider).value ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: TitenColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifikasi Peringatan', style: TitenTypography.titleLarge),
                  Text('${alerts.length} Terkini', style: TitenTypography.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              if (alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, size: 40, color: TitenColors.statusAman),
                        const SizedBox(height: 8),
                        Text('Tidak ada peringatan aktif.', style: TitenTypography.bodyLarge),
                        Text('Semua sektor dalam kondisi aman & stabil.', style: TitenTypography.bodySmall),
                      ],
                    ),
                  ),
                )
              else
                ...alerts.map((a) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.warning, color: TitenColors.statusAwasLongsor),
                        title: Text(a.title, style: TitenTypography.bodyLarge),
                        subtitle: Text(a.description, style: TitenTypography.bodySmall),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
