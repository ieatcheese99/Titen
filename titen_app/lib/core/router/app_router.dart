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
import '../constants/app_typography.dart';
import '../widgets/mode_chip.dart';
import '../widgets/responsive_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 4 Canonical Branches Router conforming to 03_APP_FLUTTER_SPEC.md §4.1
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNestedNavigation(navigationShell: navigationShell);
      },
      branches: [
        // 0. Ringkasan (Home Health)
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

        // 1. Perangkat (Devices & Sensors Hub)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/devices',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: SensorListScreen()),
              ),
              routes: [
                GoRoute(
                  path: 'nodes/:id',
                  pageBuilder: (context, state) {
                    final id = int.tryParse(state.pathParameters['id'] ?? '1') ?? 1;
                    return MaterialPage(
                      child: ResponsiveShell(child: SensorDetailScreen(nodeId: id)),
                    );
                  },
                ),
                GoRoute(
                  path: 'map',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ResponsiveShell(child: SensorMapScreen()),
                  ),
                ),
                GoRoute(
                  path: 'analytics',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ResponsiveShell(child: AnalyticsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Peringatan (Disaster Alerts & EWS Command Hub)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: EmergencyScreen()),
              ),
              routes: [
                GoRoute(
                  path: ':alertId',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ResponsiveShell(child: EmergencyScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3. Alat & Pengaturan (Diagnostics & Tools)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tools',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ResponsiveShell(child: SettingsScreen()),
              ),
              routes: [
                GoRoute(
                  path: 'settings',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ResponsiveShell(child: SettingsScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // Backward compatibility redirects (03_APP_FLUTTER_SPEC.md §4.1)
    GoRoute(
      path: '/sensors',
      redirect: (context, state) => '/devices',
    ),
    GoRoute(
      path: '/sensors/:id',
      redirect: (context, state) => '/devices/nodes/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/map',
      redirect: (context, state) => '/devices/map',
    ),
    GoRoute(
      path: '/analytics',
      redirect: (context, state) => '/devices/analytics',
    ),
    GoRoute(
      path: '/emergency',
      redirect: (context, state) => '/alerts',
    ),
    GoRoute(
      path: '/settings',
      redirect: (context, state) => '/tools/settings',
    ),
  ],
);

/// Adaptive Shell supporting Mobile (<640dp), Tablet (640-1024dp), and Desktop (>1024dp)
/// Conforming strictly to 04_RESPONSIVE_MATRIX.md §2 & 03_APP_FLUTTER_SPEC.md §4.1
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
    final tokens = context.titenTokens;
    final alertsAsync = ref.watch(alertsProvider);
    final activeAlertsCount = alertsAsync.value?.where((a) => !a.resolved).length ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isTablet = w >= 640 && w <= 1024;
        final isDesktop = w > 1024;

        // 1. Desktop Layout (> 1024dp): Fixed Sidebar (240dp)
        if (isDesktop) {
          return Scaffold(
            backgroundColor: tokens.surfaceCanvas,
            body: Row(
              children: [
                _buildDesktopSidebar(context, tokens, activeAlertsCount),
                VerticalDivider(width: 1, color: tokens.borderSubtle),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // 2. Tablet Layout (640dp - 1024dp): Adaptive NavigationRail (72dp)
        if (isTablet) {
          return Scaffold(
            backgroundColor: tokens.surfaceCanvas,
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  backgroundColor: tokens.surfacePanel,
                  indicatorColor: tokens.actionPrimaryBg.withValues(alpha: 0.12),
                  selectedIconTheme: IconThemeData(color: tokens.actionPrimaryBg),
                  unselectedIconTheme: IconThemeData(color: tokens.textSecondary),
                  selectedLabelTextStyle: TextStyle(
                    color: tokens.actionPrimaryBg,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: TextStyle(
                    color: tokens.textMetadata,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: tokens.actionPrimaryBg.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: tokens.actionPrimaryBg.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'TITEN',
                        style: TitenTypography.technical(color: tokens.actionPrimaryBg).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Ringkasan'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.sensors_outlined),
                      selectedIcon: Icon(Icons.sensors_rounded),
                      label: Text('Perangkat'),
                    ),
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: activeAlertsCount > 0,
                        label: Text('$activeAlertsCount'),
                        child: const Icon(Icons.warning_amber_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: activeAlertsCount > 0,
                        label: Text('$activeAlertsCount'),
                        child: const Icon(Icons.warning_amber_rounded),
                      ),
                      label: const Text('Peringatan'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: Text('Alat'),
                    ),
                  ],
                ),
                VerticalDivider(width: 1, color: tokens.borderSubtle),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        // 3. Mobile Layout (< 640dp): Material 3 NavigationBar
        return Scaffold(
          backgroundColor: tokens.surfaceCanvas,
          body: navigationShell,
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              height: 64,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Ringkasan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.sensors_outlined),
                  selectedIcon: Icon(Icons.sensors_rounded),
                  label: 'Perangkat',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: activeAlertsCount > 0,
                    label: Text('$activeAlertsCount'),
                    child: const Icon(Icons.warning_amber_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: activeAlertsCount > 0,
                    label: Text('$activeAlertsCount'),
                    child: const Icon(Icons.warning_amber_rounded),
                  ),
                  label: 'Peringatan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Alat',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, TitenTokens tokens, int alertCount) {
    return Container(
      width: 250,
      color: tokens.surfacePanel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Branding & ModeChip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: tokens.actionPrimaryBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'TITEN',
                          style: TitenTypography.sectionTitle(color: tokens.actionPrimaryBg).copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const ModeChip(),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Sistem EWS Bencana Geologis (MAGE 12)',
                  style: TitenTypography.metadata(color: tokens.textMetadata).copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.borderSubtle),
          const SizedBox(height: 10),

          // 4 Navigation Items
          _sidebarItem(tokens, 0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Ringkasan'),
          _sidebarItem(tokens, 1, Icons.sensors_outlined, Icons.sensors_rounded, 'Perangkat'),
          _sidebarItem(tokens, 2, Icons.warning_amber_outlined, Icons.warning_amber_rounded, 'Peringatan', badgeCount: alertCount),
          _sidebarItem(tokens, 3, Icons.tune_outlined, Icons.tune_rounded, 'Alat & Pengaturan'),

          const Spacer(),
          Divider(height: 1, color: tokens.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 16, color: tokens.actionPrimaryBg),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'TITEN v1.0.0 (Asia/Jakarta)',
                    style: TitenTypography.technical(color: tokens.textMetadata).copyWith(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    TitenTokens tokens,
    int index,
    IconData icon,
    IconData selectedIcon,
    String title, {
    int badgeCount = 0,
  }) {
    final isSelected = navigationShell.currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () => _goBranch(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? tokens.actionPrimaryBg.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected ? Border.all(color: tokens.actionPrimaryBg.withValues(alpha: 0.25), width: 1) : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected ? tokens.actionPrimaryBg : tokens.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TitenTypography.body(
                    color: isSelected ? tokens.actionPrimaryBg : tokens.textSecondary,
                  ).copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.critical.fg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
