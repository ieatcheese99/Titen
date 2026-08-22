import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

class ScaffoldWithNestedNavigation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          // Desktop sidebar layout
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _goBranch,
                  backgroundColor: TitenColors.surfaceWhite,
                  selectedIconTheme: const IconThemeData(color: TitenColors.primaryAccent),
                  unselectedIconTheme: const IconThemeData(color: TitenColors.textMuted),
                  selectedLabelTextStyle: const TextStyle(color: TitenColors.primaryAccent, fontWeight: FontWeight.bold),
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TitenColors.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield, color: TitenColors.primaryAccent, size: 24),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map),
                      label: Text('Peta'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.analytics_outlined),
                      selectedIcon: Icon(Icons.analytics),
                      label: Text('Analytics'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.sensors_outlined),
                      selectedIcon: Icon(Icons.sensors),
                      label: Text('Sensors'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.emergency_outlined),
                      selectedIcon: Icon(Icons.emergency),
                      label: Text('Emergency'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
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

        // Mobile Bottom Navigation Bar Layout
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
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map_outlined),
                  activeIcon: Icon(Icons.map),
                  label: 'Peta',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.analytics_outlined),
                  activeIcon: Icon(Icons.analytics),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sensors_outlined),
                  activeIcon: Icon(Icons.sensors),
                  label: 'Sensors',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.emergency_outlined),
                  activeIcon: Icon(Icons.emergency),
                  label: 'Emergency',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
