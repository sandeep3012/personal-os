import 'package:application/src/routing/route_definition.dart';

/// Mutable registry of [RouteDefinition]s.
///
/// Feature packages and the application module call [register] at startup to
/// declare their routes. The [ApplicationRouter] resolves paths against this
/// registry at navigation time.
///
/// Duplicate registrations (same [RouteDefinition.path] or
/// [RouteDefinition.name]) throw an [ArgumentError] to catch misconfigured
/// route tables at startup rather than at navigation time.
final class RouteRegistry {
  final _byPath = <String, RouteDefinition>{};
  final _byName = <String, RouteDefinition>{};

  /// All registered route definitions, in registration order.
  List<RouteDefinition> get routes => List.unmodifiable(_byPath.values);

  /// Registers [route].
  ///
  /// Throws [ArgumentError] if a route with the same [RouteDefinition.path] or
  /// [RouteDefinition.name] has already been registered.
  void register(RouteDefinition route) {
    if (_byPath.containsKey(route.path)) {
      throw ArgumentError.value(
        route.path,
        'route.path',
        'A route with path "${route.path}" is already registered.',
      );
    }
    if (_byName.containsKey(route.name)) {
      throw ArgumentError.value(
        route.name,
        'route.name',
        'A route with name "${route.name}" is already registered.',
      );
    }
    _byPath[route.path] = route;
    _byName[route.name] = route;
  }

  /// Returns the route registered for [path], or `null` if none.
  RouteDefinition? findByPath(String path) => _byPath[path];

  /// Returns the route registered for [name], or `null` if none.
  RouteDefinition? findByName(String name) => _byName[name];

  /// Whether any route is registered for [path].
  bool containsPath(String path) => _byPath.containsKey(path);

  /// Whether any route is registered for [name].
  bool containsName(String name) => _byName.containsKey(name);

  /// Total number of registered routes.
  int get length => _byPath.length;

  /// Whether no routes have been registered.
  bool get isEmpty => _byPath.isEmpty;

  /// Whether at least one route has been registered.
  bool get isNotEmpty => _byPath.isNotEmpty;
}
