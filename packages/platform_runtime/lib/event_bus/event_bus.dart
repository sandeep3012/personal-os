import 'dart:async';

import 'package:platform_runtime/event_bus/event_subscription.dart';
import 'package:platform_runtime/event_bus/i_event.dart';
import 'package:platform_runtime/event_bus/i_event_bus.dart';

/// Default [IEventBus] implementation backed by Dart broadcast streams.
///
/// Each concrete event type gets its own [StreamController] created on first
/// use. A secondary broadcast controller delivers every event to
/// [subscribeToAll] subscribers regardless of type.
///
/// Events are delivered **synchronously** (`sync: true`) — all handlers for a
/// given [publish] call return before [publish] itself returns. This makes
/// ordering predictable and simplifies testing. Handlers that need to perform
/// async work should schedule it themselves (e.g. via `Future.microtask`).
///
/// Example:
/// ```dart
/// final bus = EventBus();
///
/// final sub = bus.subscribe<AppStartedEvent>((e) {
///   print('App started: ${e.timestamp}');
/// });
///
/// bus.publish(AppStartedEvent(timestamp: DateTime.now()));
/// // → 'App started: ...' printed synchronously
///
/// sub.cancel();
/// bus.dispose();
/// ```
final class EventBus implements IEventBus {
  /// All type-keyed controllers, one per event type.
  final _typed = <Type, StreamController<IEvent>>{};

  /// Receives every event for [subscribeToAll] subscribers.
  late final StreamController<IEvent> _broadcast =
      StreamController<IEvent>.broadcast(sync: true);

  bool _disposed = false;

  /// Whether [dispose] has been called.
  bool get isDisposed => _disposed;

  // ── Internal helpers ────────────────────────────────────────────────────

  StreamController<IEvent> _controllerFor(Type type) {
    return _typed.putIfAbsent(
      type,
      () => StreamController<IEvent>.broadcast(sync: true),
    );
  }

  void _assertNotDisposed() {
    if (_disposed) {
      throw StateError('EventBus has already been disposed.');
    }
  }

  // ── IEventBus ───────────────────────────────────────────────────────────

  @override
  void publish<E extends IEvent>(E event) {
    if (_disposed) return;
    // Type-specific delivery.
    _typed[E]?.add(event);
    // Broadcast delivery.
    _broadcast.add(event);
  }

  @override
  EventSubscription subscribe<E extends IEvent>(
    void Function(E event) handler,
  ) {
    _assertNotDisposed();
    // ignore: cancel_subscriptions — inner is owned by StreamEventSubscription
    final inner = _controllerFor(E)
        .stream
        .where((e) => e is E)
        .map((e) => e as E)
        .listen(handler);
    return StreamEventSubscription<E>(inner);
  }

  @override
  EventSubscription subscribeToAll(void Function(IEvent event) handler) {
    _assertNotDisposed();
    return StreamEventSubscription<IEvent>(
      _broadcast.stream.listen(handler),
    );
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final ctrl in _typed.values) {
      ctrl.close();
    }
    _typed.clear();
    _broadcast.close();
  }
}
