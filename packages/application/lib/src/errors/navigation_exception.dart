import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when a navigation operation fails.
///
/// [route] optionally identifies the path or name that could not be resolved
/// or navigated to.
///
/// Example:
/// ```dart
/// throw const NavigationException(
///   message: 'No route registered for path "/dashboard".',
///   route: '/dashboard',
/// );
/// ```
final class NavigationException extends AppException {
  const NavigationException({
    required super.message,
    this.route,
    super.cause,
    super.stackTrace,
  });

  /// The route path or name involved in the failure, or `null` if not
  /// route-specific.
  final String? route;

  @override
  bool operator ==(Object other) =>
      other is NavigationException &&
      message == other.message &&
      route == other.route &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, route, cause);

  @override
  String toString() {
    final routePart = route != null ? ', route: $route' : '';
    return 'NavigationException(message: $message$routePart)';
  }
}
