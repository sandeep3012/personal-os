/// An immutable description of a single application route.
///
/// [RouteDefinition] is a platform-independent value object. It carries the
/// [path] and human-readable [name] of a route without coupling to any
/// navigation framework.
///
/// Register instances via [RouteRegistry] and resolve them through
/// [ApplicationRouter].
///
/// Example:
/// ```dart
/// const dashboardRoute = RouteDefinition(
///   path: '/dashboard',
///   name: 'dashboard',
/// );
/// ```
final class RouteDefinition {
  const RouteDefinition({
    required this.path,
    required this.name,
  });

  /// The URL-style path for this route (e.g. `'/settings/theme'`).
  final String path;

  /// A short, stable identifier used for named navigation (e.g. `'settings'`).
  final String name;

  @override
  bool operator ==(Object other) =>
      other is RouteDefinition &&
      path == other.path &&
      name == other.name;

  @override
  int get hashCode => Object.hash(path, name);

  @override
  String toString() => 'RouteDefinition(path: $path, name: $name)';
}
