import 'package:platform_core/di/i_dependency_registrar.dart';

/// A self-contained unit of dependency registration.
///
/// Each feature or package implements [IModule] to declare its own services.
/// The application bootstrap iterates over all modules and calls [register]
/// in dependency order.
///
/// Example:
/// ```dart
/// class LoggingModule implements IModule {
///   @override
///   void register(IDependencyRegistrar registrar) {
///     registrar.registerSingleton<ILogger>(Logger(tag: 'App'));
///   }
/// }
/// ```
abstract interface class IModule {
  /// Registers all services owned by this module into [registrar].
  void register(IDependencyRegistrar registrar);
}
