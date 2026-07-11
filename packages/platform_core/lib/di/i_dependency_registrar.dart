/// Write-only interface for registering dependencies during application startup.
///
/// Implementations wrap a concrete DI container (e.g. GetIt). Feature
/// packages receive a [IDependencyRegistrar] and register their own services
/// without depending on the container directly.
abstract interface class IDependencyRegistrar {
  /// Registers a pre-created [instance] as a singleton.
  ///
  /// The same instance is returned on every [IServiceLocator.get] call.
  void registerSingleton<T extends Object>(T instance);

  /// Registers a [factory] that creates a new instance on every
  /// [IServiceLocator.get] call.
  void registerFactory<T extends Object>(T Function() factory);

  /// Registers a [factory] whose result is cached after the first call.
  void registerLazySingleton<T extends Object>(T Function() factory);
}
