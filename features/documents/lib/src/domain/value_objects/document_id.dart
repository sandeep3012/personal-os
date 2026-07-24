/// Identity value for an [Document] aggregate root.
final class DocumentId {
  const DocumentId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DocumentId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
