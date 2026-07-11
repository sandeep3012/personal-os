import 'package:platform_runtime/lifecycle/lifecycle_observer.dart';

/// Platform-independent contract for managing application lifecycle observers.
///
/// Concrete implementations coordinate with [WidgetsBindingObserver] on Flutter
/// or the equivalent on other platforms. Feature packages subscribe to lifecycle
/// changes through this interface without depending on Flutter directly.
///
/// Register implementations via [ApplicationModule] or a platform-specific
/// module.
///
/// Example:
/// ```dart
/// lifecycleService.addObserver(cacheService);
/// // … on teardown …
/// lifecycleService.removeObserver(cacheService);
/// ```
abstract interface class AppLifecycleService {
  /// Subscribes [observer] to future lifecycle callbacks.
  ///
  /// Adding the same [observer] more than once is a no-op or results in
  /// duplicate callbacks, depending on the implementation. Prefer calling
  /// [removeObserver] before re-adding.
  void addObserver(LifecycleObserver observer);

  /// Unsubscribes [observer] from lifecycle callbacks.
  ///
  /// Safe to call when [observer] is not currently registered.
  void removeObserver(LifecycleObserver observer);
}
