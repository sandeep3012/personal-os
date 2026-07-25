/// Identity value for a [Goal] aggregate root.
final class GoalId {
  const GoalId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is GoalId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
