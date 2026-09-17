import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/application/dashboard_providers.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/sensor_map/presentation/sensor_map_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/sensors/presentation/sensor_list_screen.dart';
import '../../features/sensors/presentation/sensor_detail_screen.dart';
import '../../features/emergency/presentation/emergency_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../constants/app_colors.dart';
import '../widgets/responsive_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        // 0. Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: DashboardScreen()),
              ),
            ),
          ],
        ),

        // 1. Map
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: SensorMapScreen()),
              ),
            ),
          ],
        ),

        // 2. Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: AnalyticsScreen()),
              ),
            ),
          ],
        ),

        // 3. Sensors
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sensors',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: SensorListScreen()),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
                    return MaterialPage(
                      child: ResponsiveShell(child: SensorDetailScreen(nodeId: id)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // 4. Emergency
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/emergency',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: EmergencyScreen()),
              ),
            ),
          ],
        ),

        // 5. Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: SettingsScreen()),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

class ScaffoldWithNestedNavigation extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNestedNavigation({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoneStatus = ref.watch(overallZoneStatusProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final activeAlertsCount = alertsAsync.value?.where((a) => !a.resolved).length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWebWide = constraints.maxWidth >= 960;
        final isTablet = constraints.maxWidth >= 700 && constraints.maxWidth < 960;

        // 1. Desktop & Web Portal Layout (Expanded Sidebar)
        if (isWebWide) {
          return Scaffold(
            backgroundColor: TitenColors.baseBackground,
            body: Row(
              children: [
                _buildWebSidebar(context, zoneStatus, activeAlertsCount),
                const VerticalDivider(width: 1, color: TitenColors.outlineBorder),
                Expanded(
                  child: navigationShell,
                ),
              ],
            ),
          );
        }

        // 2. Tablet Layout (NavigationRail)
        if (isTablet) {
          return Scaffold(
            backgroundColor: TitenColors.baseBackground,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  backgroundColor: TitenColors.surfaceWhite,
                  selectedIconTheme: const IconThemeData(color: TitenColors.primaryAccent),
                  unselectedIconTheme: const IconThemeData(color: TitenColors.textMuted),
                  selectedLabelTextStyle: const TextStyle(
                    color: TitenColors.primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: TitenColors.textMuted,
                    fontSize: 11,
                  ),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TitenColors.primaryAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shield_rounded, color: TitenColors.primaryAccent, size: 26),
                    ),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: Text('Peta'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics_rounded),
                      label: Text('Analytics'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.sensors_outlined),
                      selectedIcon: Icon(Icons.sensors_rounded),
                      label: Text('Sensors'),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: activeAlertsCount > 0,
                        label: Text('$activeAlertsCount'),
                        child: const Icon(Icons.emergency_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: activeAlertsCount > 0,
                        label: Text('$activeAlertsCount'),
                        child: const Icon(Icons.emergency_rounded),
                      ),
                      label: const Text('Emergency'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: TitenColors.outlineBorder),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // 3. Mobile Layout (BottomNavigationBar)
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: TitenColors.outlineBorder, width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _goBranch,
              type: BottomNavigationBarType.fixed,
              backgroundColor: TitenColors.surfaceWhite,
              selectedItemColor: TitenColors.primaryAccent,
              unselectedItemColor: TitenColors.textMuted,
              selectedFontSize: 11,
              unselectedFontSize: 10,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map_rounded),
                  label: 'Peta',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics_rounded),
                  label: 'Analytics',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.sensors_outlined),
                  activeIcon: Icon(Icons.sensors_rounded),
                  label: 'Sensors',
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: activeAlertsCount > 0,
                    label: Text('$activeAlertsCount'),
                    child: const Icon(Icons.emergency_outlined),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: activeAlertsCount > 0,
                    label: Text('$activeAlertsCount'),
                    child: const Icon(Icons.emergency_rounded),
                  ),
                  label: 'Emergency',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebSidebar(BuildContext context, dynamic zoneStatus, int activeAlertsCount) {
    final navItems = [
      {'title': 'Dashboard Telemetri', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard_rounded},
      {'title': 'Peta Sebaran IoT', 'icon': Icons.map_outlined, 'activeIcon': Icons.map_rounded},
      {'title': 'Grafik & Tren AI', 'icon': Icons.analytics_outlined, 'activeIcon': Icons.analytics_rounded},
      {'title': 'Daftar Node Sensor', 'icon': Icons.sensors_outlined, 'activeIcon': Icons.sensors_rounded},
      {'title': 'Tanggap Darurat', 'icon': Icons.emergency_outlined, 'activeIcon': Icons.emergency_rounded, 'badge': activeAlertsCount},
      {'title': 'Pengaturan Sistem', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded},
    ];

    return Container(
      width: 270,
      color: TitenColors.surfaceWhite,
      child: Column(
        children: [
          // 1. Sidebar Brand Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [TitenColors.primaryAccent, Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: TitenColors.primaryAccent.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'TITEN',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: TitenColors.textMain,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: TitenColors.primaryAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: TitenColors.primaryAccent.withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'WEB EWS',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: TitenColors.primaryAccent,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Deteksi Longsor & Karhutla',
                        style: TextStyle(
                          fontSize: 11,
                          color: TitenColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Gateway Status Chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: TitenColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: TitenColors.outlineBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TitenColors.statusAman,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'LoRa Gateway: ONLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: TitenColors.textMain,
                      ),
                    ),
                  ),
                  const Text(
                    '4 Nodes',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: TitenColors.primaryAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: TitenColors.outlineBorder),
          const SizedBox(height: 12),

          // 3. Navigation Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: navItems.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = navigationShell.currentIndex == index;
                final badgeCount = item['badge'] as int? ?? 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _goBranch(index),
                    borderRadius: BorderRadius.circular(10),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TitenColors.primaryAccent.withValues(alpha: 0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? TitenColors.primaryAccent.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                            size: 20,
                            color: isSelected ? TitenColors.primaryAccent : TitenColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? TitenColors.primaryAccent : TitenColors.textMain,
                              ),
                            ),
                          ),
                          if (badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: TitenColors.statusAwasLongsor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 4. Sidebar Threat Status Box
          Padding(
            padding: const EdgeInsets.all(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: zoneStatus.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: zoneStatus.color.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: zoneStatus.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'STATUS JARINGAN EWS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: zoneStatus.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    zoneStatus.title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: TitenColors.textMain,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TitenColors.primaryAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.phone_in_talk, size: 14),
                      label: const Text(
                        'Tanggap Cepat SOS',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _goBranch(4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: TitenColors.outlineBorder),

          // 5. User Profile Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: TitenColors.primaryAccent.withValues(alpha: 0.15),
                  child: const Text(
                    'MG',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: TitenColors.primaryAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tim Trilogy MAGE 12',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: TitenColors.textMain),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Operator EWS • ITS',
                        style: TextStyle(fontSize: 10, color: TitenColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
