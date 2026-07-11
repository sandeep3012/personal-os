import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';

/// Configures go_router for Personal OS.
///
/// All routes are defined here. New feature routes are added in later sprints.
///
/// ## Current routes
///
/// | Path | Name   | Screen       |
/// |------|--------|--------------|
/// | `/`  | `home` | [HomeScreen] |
abstract final class AppRouter {
  /// Named route identifier for the home screen.
  static const String homeName = 'home';

  /// Path for the home screen.
  static const String homePath = '/';

  /// Creates and returns a fully configured [GoRouter].
  ///
  /// [config] is passed to the [HomeScreen] so it can display environment
  /// and version information.
  static GoRouter create({required AppConfig config}) => GoRouter(
        initialLocation: homePath,
        debugLogDiagnostics: config.isDevelopment,
        routes: <RouteBase>[
          GoRoute(
            path: homePath,
            name: homeName,
            builder: (BuildContext context, GoRouterState state) =>
                HomeScreen(config: config),
          ),
        ],
      );
}
