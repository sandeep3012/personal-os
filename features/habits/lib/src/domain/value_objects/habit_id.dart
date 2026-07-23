/// Identity value for a [Habit] aggregate root.
final class HabitId {
  const HabitId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is HabitId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
