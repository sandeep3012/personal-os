/// Platform-independent contract for imperative navigation.
///
/// Concrete implementations wrap a navigation framework (e.g. go_router) and
/// are provided by the app layer. Feature packages depend only on this
/// interface and never import the framework directly.
///
/// Example:
/// ```dart
/// class MyUseCase {
///   const MyUseCase(this._nav);
///   final NavigationService _nav;
///
///   Future<void> goToDashboard() => _nav.navigateTo('/dashboard');
/// }
/// ```
abstract interface class NavigationService {
  /// Pushes the route at [path] onto the navigation stack.
  ///
  /// [params] are passed as query or path parameters, depending on the
  /// concrete implementation.
  Future<void> navigateTo(String path, {Map<String, String>? params});

  /// Replaces the current route with the route at [path].
  Future<void> replace(String path, {Map<String, String>? params});

  /// Pops the current route off the navigation stack.
  ///
  /// No-op if [canGoBack] is `false`.
  Future<void> goBack();

  /// Returns `true` if there is a previous route to go back to.
  bool canGoBack();

  /// The path of the currently active route.
  String get currentPath;
}
