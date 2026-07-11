/// Marker base class for all events published through the [IEventBus].
///
/// Concrete event types extend this class and carry their own payload fields.
/// Events are value objects — immutable and identified by their content.
///
/// Example:
/// ```dart
/// final class UserSignedInEvent extends IEvent {
///   const UserSignedInEvent({required this.userId});
///   final String userId;
/// }
/// ```
abstract class IEvent {
  const IEvent();
}
