/// Identity value for a [Task] aggregate root.
final class TaskId {
  const TaskId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TaskId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
