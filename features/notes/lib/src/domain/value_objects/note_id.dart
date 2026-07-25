/// Identity value for a [Note] aggregate root.
final class NoteId {
  const NoteId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NoteId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
