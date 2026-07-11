import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_runtime/registry/registry_exception.dart';

/// In-memory service registry that fulfils the [IDependencyRegistrar] and
/// [IServiceLocator] contracts from `platform_core`.
///
/// Does **not** use any external DI container. All storage is map-based,
/// making the registry fully controllable in tests without global state.
///
/// ## Registration modes
///
/// | Method | Behaviour |
/// |---|---|
/// | [registerSingleton] | Pre-created instance; same object every [get] call. |
/// | [registerFactory] | Factory invoked on **every** [get] call. |
/// | [registerLazySingleton] | Factory invoked once on **first** [get] call; result cached. |
///
/// ## Example
///
/// ```dart
/// final registry = ServiceRegistry();
/// registry.registerSingleton<ILogger>(Logger(tag: 'App'));
/// registry.registerLazySingleton<IEventBus>(() => EventBus());
///
/// final logger = registry.get<ILogger>();
/// final bus    = registry.get<IEventBus>(); // created on first access
/// ```
final class ServiceRegistry implements IDependencyRegistrar, IServiceLocator {
  final _singletons = <Type, Object>{};
  final _factories = <Type, Object Function()>{};
  final _lazySingletonFactories = <Type, Object Function()>{};
  final _lazySingletonCache = <Type, Object>{};

  // ── IDependencyRegistrar ─────────────────────────────────────────────────

  @override
  void registerSingleton<T extends Object>(T instance) {
    _assertNotAlreadyRegistered<T>();
    _singletons[T] = instance;
  }

  @override
  void registerFactory<T extends Object>(T Function() factory) {
    _assertNotAlreadyRegistered<T>();
    _factories[T] = factory;
  }

  @override
  void registerLazySingleton<T extends Object>(T Function() factory) {
    _assertNotAlreadyRegistered<T>();
    _lazySingletonFactories[T] = factory;
  }

  // ── IServiceLocator ──────────────────────────────────────────────────────

  @override
  T get<T extends Object>() {
    // 1. Pre-created singleton.
    final singleton = _singletons[T];
    if (singleton != null) return singleton as T;

    // 2. Factory — new instance each time.
    final factory = _factories[T];
    if (factory != null) return factory() as T;

    // 3. Lazy singleton — create and cache on first access.
    final lazyFactory = _lazySingletonFactories[T];
    if (lazyFactory != null) {
      final cached = _lazySingletonCache.putIfAbsent(T, lazyFactory);
      return cached as T;
    }

    throw RegistryException(
      message: 'No registration found for type $T. '
          'Did you forget to call register before get?',
    );
  }

  @override
  bool isRegistered<T extends Object>() =>
      _singletons.containsKey(T) ||
      _factories.containsKey(T) ||
      _lazySingletonFactories.containsKey(T);

  // ── Extended registry API ────────────────────────────────────────────────

  /// Alias for [isRegistered] — matches the service-locator vocabulary
  /// used elsewhere in the codebase.
  bool contains<T extends Object>() => isRegistered<T>();

  /// Removes the registration for type [T].
  ///
  /// Clears both the factory/singleton entry and any cached lazy-singleton
  /// value. Safe to call when [T] is not registered.
  void unregister<T extends Object>() {
    _singletons.remove(T);
    _factories.remove(T);
    _lazySingletonFactories.remove(T);
    _lazySingletonCache.remove(T);
  }

  /// Removes **all** registrations and clears every cache.
  ///
  /// Primarily useful in test tear-down to restore a clean state.
  void reset() {
    _singletons.clear();
    _factories.clear();
    _lazySingletonFactories.clear();
    _lazySingletonCache.clear();
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  void _assertNotAlreadyRegistered<T extends Object>() {
    if (isRegistered<T>()) {
      throw RegistryException(
        message: 'Type $T is already registered. '
            'Call unregister<$T>() before re-registering.',
      );
    }
  }
}
