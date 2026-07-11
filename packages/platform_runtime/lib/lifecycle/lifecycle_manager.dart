import 'package:platform_runtime/lifecycle/lifecycle_exception.dart';
import 'package:platform_runtime/lifecycle/lifecycle_observer.dart';
import 'package:platform_runtime/lifecycle/lifecycle_state.dart';

/// Manages the runtime lifecycle state machine and notifies observers.
///
/// ## Valid transitions
///
/// ```
/// uninitialized → initialized → started ⇄ paused → stopped → disposed
/// ```
///
/// Any call that would violate this graph throws a [LifecycleException].
/// Once [dispose] is called the manager is permanently terminal — no further
/// transitions are accepted.
///
/// ## Usage
///
/// ```dart
/// final manager = LifecycleManager();
/// manager.addObserver(myService);
///
/// await manager.initialize();
/// await manager.start();
/// // … app is running …
/// await manager.pause();
/// await manager.resume();
/// await manager.stop();
/// await manager.dispose();
/// ```
final class LifecycleManager {
  final _observers = <LifecycleObserver>[];
  LifecycleState _state = LifecycleState.uninitialized;

  /// The current lifecycle state.
  LifecycleState get state => _state;

  // ── Observer management ───────────────────────────────────────────────────

  /// Registers [observer] to receive future lifecycle callbacks.
  ///
  /// Adding the same observer twice is safe — the second call is ignored.
  void addObserver(LifecycleObserver observer) {
    if (!_observers.contains(observer)) _observers.add(observer);
  }

  /// Removes [observer] so it no longer receives callbacks.
  ///
  /// Safe to call when [observer] is not registered.
  void removeObserver(LifecycleObserver observer) => _observers.remove(observer);

  // ── Lifecycle transitions ─────────────────────────────────────────────────

  /// Transitions from [LifecycleState.uninitialized] to
  /// [LifecycleState.initialized] and notifies observers.
  void initialize() {
    _assertCanTransition(
      from: LifecycleState.uninitialized,
      to: LifecycleState.initialized,
    );
    _state = LifecycleState.initialized;
    _notifyAll((o) => o.onInitialize());
  }

  /// Transitions from [LifecycleState.initialized] to
  /// [LifecycleState.started] and notifies observers.
  void start() {
    _assertCanTransition(
      from: LifecycleState.initialized,
      to: LifecycleState.started,
    );
    _state = LifecycleState.started;
    _notifyAll((o) => o.onStart());
  }

  /// Transitions from [LifecycleState.started] to
  /// [LifecycleState.paused] and notifies observers.
  void pause() {
    _assertCanTransition(
      from: LifecycleState.started,
      to: LifecycleState.paused,
    );
    _state = LifecycleState.paused;
    _notifyAll((o) => o.onPause());
  }

  /// Transitions from [LifecycleState.paused] back to
  /// [LifecycleState.started] and notifies observers.
  void resume() {
    _assertCanTransition(
      from: LifecycleState.paused,
      to: LifecycleState.started,
    );
    _state = LifecycleState.started;
    _notifyAll((o) => o.onResume());
  }

  /// Transitions from [LifecycleState.started] to
  /// [LifecycleState.stopped] and notifies observers.
  void stop() {
    _assertCanTransition(
      from: LifecycleState.started,
      to: LifecycleState.stopped,
    );
    _state = LifecycleState.stopped;
    _notifyAll((o) => o.onStop());
  }

  /// Transitions from [LifecycleState.stopped] to
  /// [LifecycleState.disposed] and notifies observers.
  ///
  /// After this call all future transitions throw [LifecycleException].
  void dispose() {
    _assertCanTransition(
      from: LifecycleState.stopped,
      to: LifecycleState.disposed,
    );
    _state = LifecycleState.disposed;
    _notifyAll((o) => o.onDispose());
    _observers.clear();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _assertCanTransition({
    required LifecycleState from,
    required LifecycleState to,
  }) {
    if (_state != from) {
      throw LifecycleException(
        message: 'Cannot transition to $to: '
            'expected state $from but current state is $_state.',
      );
    }
  }

  void _notifyAll(void Function(LifecycleObserver) callback) {
    // Iterate over a copy so observers can safely remove themselves
    // during a callback without causing concurrent-modification errors.
    for (final observer in List.of(_observers)) {
      callback(observer);
    }
  }
}
