import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Icon/label metadata for one [StatefulShellBranch]'s navigation
/// destination — the single source [AppShell] reads to build both the
/// `NavigationBar` (compact) and `NavigationRail` (medium/expanded), so the
/// two adaptive layouts can never drift out of sync with each other or with
/// the branch list itself (TIS §4).
final class ShellDestination {
  const ShellDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// The Personal OS shell's top-level branches (Milestone 1A: Home, Finance,
/// Settings; Tasks added in Milestone 7).
///
/// Adding a future module means adding one branch here and one
/// [ShellDestination] here — no other app-layer file changes (TIS §4
/// "Future extensibility").
abstract final class ShellBranches {
  static const String homePath = '/';
  static const String homeName = 'home';

  static const String tasksPath = '/tasks';
  static const String tasksName = 'tasks';

  static const String habitsPath = '/habits';
  static const String habitsName = 'habits';

  static const String settingsPath = '/settings';
  static const String settingsName = 'settings';

  /// Destinations in the same order as [build]'s branches — index N here
  /// corresponds to branch N.
  static const List<ShellDestination> destinations = [
    ShellDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: 'Home',
    ),
    ShellDestination(
      icon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet,
      label: 'Finance',
    ),
    ShellDestination(
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      label: 'Tasks',
    ),
    ShellDestination(
      icon: Icons.local_fire_department_outlined,
      selectedIcon: Icons.local_fire_department,
      label: 'Habits',
    ),
    ShellDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  /// Builds the branch list. [financeRoutes] are the existing Finance
  /// [GoRoute]s (Dashboard/Accounts/Transactions/Categories), unchanged from
  /// today — this milestone only relocates them under the Finance branch,
  /// it does not alter their paths, names, or builders (TIS Milestone 1
  /// exit criteria: "Finance functionality must remain identical").
  ///
  /// [homeBuilder] renders the Home branch's landing screen — the real
  /// [HomeDashboardPage] (Milestone 5 Part B), DI-resolved by the app layer
  /// exactly like [financeRoutes]' own builders.
  /// [settingsBuilder] renders the Settings branch's landing screen — the
  /// real [SettingsPage] (Milestone 6 Part E), DI-resolved the same way.
  /// [tasksBuilder] renders the Tasks branch's landing screen — the real
  /// [TasksPage] (Milestone 7), DI-resolved the same way.
  static List<StatefulShellBranch> build({
    required List<RouteBase> financeRoutes,
    required Widget Function(BuildContext context, GoRouterState state) homeBuilder,
    required Widget Function(BuildContext context, GoRouterState state) settingsBuilder,
    required Widget Function(BuildContext context, GoRouterState state) tasksBuilder,
    required Widget Function(BuildContext context, GoRouterState state) habitsBuilder,
  }) =>
      [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: homePath,
              name: homeName,
              builder: homeBuilder,
            ),
          ],
        ),
        StatefulShellBranch(routes: financeRoutes),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: tasksPath,
              name: tasksName,
              builder: tasksBuilder,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: habitsPath,
              name: habitsName,
              builder: habitsBuilder,
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: settingsPath,
              name: settingsName,
              builder: settingsBuilder,
            ),
          ],
        ),
      ];
}
