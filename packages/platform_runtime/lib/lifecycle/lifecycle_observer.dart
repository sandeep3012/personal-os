/// Receives lifecycle callbacks from [LifecycleManager].
///
/// Implement this interface on any object that needs to react to runtime
/// lifecycle transitions. Register via [LifecycleManager.addObserver].
///
/// All methods have default no-op implementations so you only override the
/// callbacks you care about.
///
/// Example:
/// ```dart
/// class CacheService implements LifecycleObserver {
///   @override
///   void onStart() => _cache.warmUp();
///
///   @override
///   void onStop() => _cache.flush();
/// }
/// ```
abstract interface class LifecycleObserver {
  /// Called when the runtime transitions to [LifecycleState.initialized].
  void onInitialize() {}

  /// Called when the runtime transitions to [LifecycleState.started].
  void onStart() {}

  /// Called when the runtime transitions to [LifecycleState.paused].
  void onPause() {}

  /// Called when the runtime transitions back to [LifecycleState.started]
  /// from [LifecycleState.paused].
  void onResume() {}

  /// Called when the runtime transitions to [LifecycleState.stopped].
  void onStop() {}

  /// Called when the runtime transitions to [LifecycleState.disposed].
  void onDispose() {}
}
