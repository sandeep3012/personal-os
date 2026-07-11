import 'package:application/src/errors/navigation_exception.dart';
import 'package:application/src/routing/route_definition.dart';
import 'package:application/src/routing/route_registry.dart';

/// Platform-independent router that resolves paths and names to
/// [RouteDefinition]s registered in a [RouteRegistry].
///
/// [ApplicationRouter] is a pure lookup layer; it does not perform navigation
/// itself. Pair it with a [NavigationService] implementation for actual
/// navigation.
///
/// Example:
/// ```dart
/// final router = ApplicationRouter(registry: routeRegistry);
/// final route = router.resolveByPath('/dashboard');
/// ```
final class ApplicationRouter {
  const ApplicationRouter({required this.registry});

  /// The route registry this router resolves against.
  final RouteRegistry registry;

  /// Returns the [RouteDefinition] for [path].
  ///
  /// Throws [NavigationException] if no route is registered for [path].
  RouteDefinition resolveByPath(String path) {
    final route = registry.findByPath(path);
    if (route == null) {
      throw NavigationException(
        message: 'No route registered for path "$path".',
        route: path,
      );
    }
    return route;
  }

  /// Returns the [RouteDefinition] for [name].
  ///
  /// Throws [NavigationException] if no route is registered for [name].
  RouteDefinition resolveByName(String name) {
    final route = registry.findByName(name);
    if (route == null) {
      throw NavigationException(
        message: 'No route registered with name "$name".',
        route: name,
      );
    }
    return route;
  }

  /// Returns `true` if a route is registered for [path].
  bool canResolveByPath(String path) => registry.containsPath(path);

  /// Returns `true` if a route is registered for [name].
  bool canResolveByName(String name) => registry.containsName(name);
}
