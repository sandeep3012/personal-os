/// Identity value for an [Account] aggregate root.
final class AccountId {
  const AccountId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AccountId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
