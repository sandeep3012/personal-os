/// Identity value for an [Event] aggregate root.
final class EventId {
  const EventId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EventId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
