import 'package:platform_runtime/event_bus/i_event.dart';

/// Marker base class for application-level events.
///
/// [AppEvent]s model cross-cutting concerns that span features or layers —
/// for example, session changes, connectivity changes, or feature-flag
/// refreshes. They are distinct from [DomainEvent]s, which model business
/// facts within a bounded context.
///
/// Publish and subscribe to [AppEvent]s through the [IEventBus] registered
/// in the DI container by [ApplicationModule].
///
/// Example:
/// ```dart
/// final class ConnectivityChangedEvent extends AppEvent {
///   const ConnectivityChangedEvent({required this.isOnline});
///   final bool isOnline;
/// }
/// ```
abstract class AppEvent extends IEvent {
  const AppEvent();
}
