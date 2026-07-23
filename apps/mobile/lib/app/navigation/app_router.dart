import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';
import 'package:personal_os/app/shell/app_shell.dart';
import 'package:personal_os/app/shell/shell_branches.dart';

/// Configures go_router for Personal OS.
///
/// ## Route architecture (ADR-003 + Milestone 1A AppShell)
///
/// ```
/// RouteRegistry (application)   — platform-independent route catalog
///   ↓ populated by feature modules at boot
/// AppRouter (apps/mobile)       — bridge from RouteRegistry to go_router
///   ↓ injects feature GoRoute list into the appropriate shell branch
/// StatefulShellRoute            — Home / Finance / Settings branches,
///                                  each its own independent Navigator
///   ↓
/// GoRouter                      — Flutter navigation engine
/// ```
///
/// Feature packages register [RouteDefinition]s in [RouteRegistry] during
/// [FeatureModule.register]. The app layer maps each [RouteDefinition] to a
/// concrete [GoRoute] (with a Flutter builder) and passes Finance's routes
/// to [AppRouter.create] via [financeRoutes]; [ShellBranches.build] places
/// them inside the Finance branch.
///
/// Feature packages never import go_router directly. They navigate via
/// [NavigationService] (full implementation deferred to Sprint 8).
///
/// ## Current routes
///
/// | Path            | Name          | Screen             | Source        |
/// |------------------|---------------|--------------------|---------------|
/// | `/`              | `home`        | Home placeholder    | Shell branch  |
/// | `/finance/...`   | `finance-...` | Finance pages       | Shell branch  |
/// | `/settings`      | `settings`    | Settings placeholder| Shell branch  |
/// | `/diagnostics`   | `diagnostics` | [HomeScreen]        | Top-level     |
/// | `/sample`        | `sample`      | Sample page         | Top-level     |
///
/// Home, Finance, and Settings live inside one [StatefulShellRoute] wrapped
/// by [AppShell] (persistent bottom nav / rail — TIS §4). Diagnostics and
/// Sample remain plain top-level routes outside the shell — neither is a
/// primary navigation destination (Milestone 1A does not touch either).
abstract final class AppRouter {
  /// Named route identifier for the platform diagnostics screen.
  static const String diagnosticsName = 'diagnostics';

  /// Path for the platform diagnostics screen.
  static const String diagnosticsPath = '/diagnostics';

  /// Creates and returns a fully configured [GoRouter].
  ///
  /// [config] is passed to the diagnostics screen for environment/version
  /// display.
  ///
  /// [homeBuilder] renders the Home branch's landing screen — the app
  /// layer's DI-resolved [HomeDashboardPage] (Milestone 5 Part B).
  ///
  /// [settingsBuilder] renders the Settings branch's landing screen — the
  /// app layer's DI-resolved [SettingsPage] (Milestone 6 Part E).
  ///
  /// [demoModeController] drives the persistent [DemoModeBanner] [AppShell]
  /// shows above every branch while Demo Mode is active.
  ///
  /// [financeRoutes] are the existing Finance [GoRoute]s
  /// (Dashboard/Accounts/Transactions/Categories), placed inside the shell's
  /// Finance branch by [ShellBranches.build] — unchanged from before this
  /// milestone.
  ///
  /// [otherTopLevelRoutes] are routes that stay outside the shell (e.g. the
  /// Sample feature's route) — appended alongside the (also top-level)
  /// diagnostics route.
  ///
  /// [initialLocation] is the path the app boots into. Defaults to
  /// [ShellBranches.homePath] — Home is the application's true root
  /// (Architecture Proposal §2.1); Finance is a module reachable through
  /// the shell, not the app's landing screen.
  static GoRouter create({
    required AppConfig config,
    required Widget Function(BuildContext context, GoRouterState state) homeBuilder,
    required Widget Function(BuildContext context, GoRouterState state) settingsBuilder,
    required Widget Function(BuildContext context, GoRouterState state) tasksBuilder,
    required DemoModeController demoModeController,
    List<RouteBase> financeRoutes = const [],
    List<RouteBase> otherTopLevelRoutes = const [],
    String initialLocation = ShellBranches.homePath,
  }) =>
      GoRouter(
        initialLocation: initialLocation,
        debugLogDiagnostics: config.isDevelopment,
        routes: <RouteBase>[
          GoRoute(
            path: diagnosticsPath,
            name: diagnosticsName,
            builder: (BuildContext context, GoRouterState state) =>
                HomeScreen(config: config),
          ),
          ...otherTopLevelRoutes,
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => AppShell(
              navigationShell: navigationShell,
              demoModeController: demoModeController,
            ),
            branches: ShellBranches.build(
              financeRoutes: financeRoutes,
              homeBuilder: homeBuilder,
              settingsBuilder: settingsBuilder,
              tasksBuilder: tasksBuilder,
            ),
          ),
        ],
      );
}
