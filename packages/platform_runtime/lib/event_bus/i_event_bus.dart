import 'package:platform_runtime/event_bus/event_subscription.dart';
import 'package:platform_runtime/event_bus/i_event.dart';

/// Contract for the application-wide event bus.
///
/// The event bus enables decoupled communication between modules and features
/// without direct references. Publishers and subscribers never know about each
/// other.
///
/// ## Usage pattern
///
/// ```dart
/// // Publisher (e.g. AuthRepository):
/// eventBus.publish(UserSignedInEvent(userId: '123'));
///
/// // Subscriber (e.g. AnalyticsService):
/// final sub = eventBus.subscribe<UserSignedInEvent>((e) {
///   analytics.track('sign_in', {'user': e.userId});
/// });
///
/// // Cleanup:
/// sub.cancel();
/// ```
///
/// ## Constraints
/// - No event persistence or replay.
/// - No sticky events.
/// - Events are delivered synchronously to all current subscribers.
abstract interface class IEventBus {
  /// Publishes [event] to all active subscribers of type [E].
  ///
  /// If no subscribers exist for [E], the event is silently discarded.
  /// Also delivered to [subscribeToAll] broadcast subscribers.
  void publish<E extends IEvent>(E event);

  /// Subscribes [handler] to events of type [E].
  ///
  /// Returns an [EventSubscription] that must be [cancel]led when the
  /// subscriber is disposed to prevent memory leaks.
  EventSubscription subscribe<E extends IEvent>(
    void Function(E event) handler,
  );

  /// Subscribes [handler] to **all** events regardless of type.
  ///
  /// Use for cross-cutting concerns (audit log, analytics, debug logging)
  /// that must observe every event in the system.
  EventSubscription subscribeToAll(void Function(IEvent event) handler);

  /// Disposes the event bus.
  ///
  /// Closes all stream controllers and prevents further publishing or
  /// subscribing. Active [EventSubscription]s become inert.
  void dispose();
}
