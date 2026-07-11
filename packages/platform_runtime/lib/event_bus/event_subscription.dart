import 'dart:async';

/// An opaque handle to an active event subscription.
///
/// Returned by [IEventBus.subscribe] and [IEventBus.subscribeToAll].
/// Call [cancel] to stop receiving events and free resources.
///
/// Example:
/// ```dart
/// final sub = bus.subscribe<AppStartedEvent>((e) => print('started'));
/// // ...later...
/// sub.cancel();
/// ```
abstract interface class EventSubscription {
  /// Cancels this subscription, removing the handler from the event bus.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  void cancel();
}

/// Internal [EventSubscription] backed by a Dart [StreamSubscription].
final class StreamEventSubscription<E> implements EventSubscription {
  StreamEventSubscription(this._inner);

  final StreamSubscription<E> _inner;
  bool _cancelled = false;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _inner.cancel();
  }
}
