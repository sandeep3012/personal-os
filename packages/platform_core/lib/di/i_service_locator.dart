/// Read-only accessor for registered dependencies.
///
/// The concrete implementation (e.g. a GetIt wrapper) is provided by the
/// application bootstrap layer — feature packages depend only on this
/// interface.
///
/// Example:
/// ```dart
/// final logger = locator.get<ILogger>();
/// ```
abstract interface class IServiceLocator {
  /// Returns the registered instance of type [T].
  ///
  /// Throws a [StateError] if [T] has not been registered.
  T get<T extends Object>();

  /// Returns `true` if an instance of type [T] has been registered.
  bool isRegistered<T extends Object>();
}
