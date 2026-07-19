/// Identity value for a [Transaction] aggregate root.
final class TransactionId {
  const TransactionId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
