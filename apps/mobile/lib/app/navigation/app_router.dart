import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';

/// Configures go_router for Personal OS.
///
/// ## Route architecture (ADR-003)
///
/// ```
/// RouteRegistry (application)   — platform-independent route catalog
///   ↓ populated by feature modules at boot
/// AppRouter (apps/mobile)       — bridge from RouteRegistry to go_router
///   ↓ injects feature GoRoute list
/// GoRouter                      — Flutter navigation engine
/// ```
///
/// Feature packages register [RouteDefinition]s in [RouteRegistry] during
/// [FeatureModule.register]. The app layer maps each [RouteDefinition] to a
/// concrete [GoRoute] (with a Flutter builder) and passes the list to
/// [AppRouter.create] via [featureRoutes].
///
/// Feature packages never import go_router directly. They navigate via
/// [NavigationService] (full implementation deferred to Sprint 8).
///
/// ## Current routes
///
/// | Path      | Name     | Screen        | Source   |
/// |-----------|----------|---------------|----------|
/// | `/`       | `home`   | [HomeScreen]  | Shell    |
/// | `/sample` | `sample` | [SamplePage]  | Feature  |
abstract final class AppRouter {
  /// Named route identifier for the home screen.
  static const String homeName = 'home';

  /// Path for the home screen.
  static const String homePath = '/';

  /// Creates and returns a fully configured [GoRouter].
  ///
  /// [config] is passed to the home screen for environment/version display.
  ///
  /// [featureRoutes] is the list of [RouteBase] entries contributed by feature
  /// packages. The app layer builds these from each feature's exported route
  /// constants and page widgets. They are appended after the shell routes.
  static GoRouter create({
    required AppConfig config,
    List<RouteBase> featureRoutes = const [],
  }) =>
      GoRouter(
        initialLocation: homePath,
        debugLogDiagnostics: config.isDevelopment,
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            name: homeName,
            builder: (BuildContext context, GoRouterState state) =>
                HomeScreen(config: config),
          ),
          ...featureRoutes,
        ],
      );
}
