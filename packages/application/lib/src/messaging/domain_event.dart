import 'package:platform_runtime/event_bus/i_event.dart';

/// Marker base class for domain (business) events.
///
/// [DomainEvent]s represent facts that occurred in a bounded context —
/// for example, "a transaction was recorded" or "a goal was completed".
/// They are distinct from [AppEvent]s, which model infrastructure-level
/// or cross-cutting concerns.
///
/// Publish and subscribe to [DomainEvent]s through the [IEventBus] registered
/// in the DI container by [ApplicationModule].
///
/// Example:
/// ```dart
/// final class TransactionRecordedEvent extends DomainEvent {
///   const TransactionRecordedEvent({
///     required this.transactionId,
///     required this.amount,
///   });
///   final String transactionId;
///   final double amount;
/// }
/// ```
abstract class DomainEvent extends IEvent {
  const DomainEvent();
}
