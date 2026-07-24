/// Identity value for an [Asset] aggregate root.
final class AssetId {
  const AssetId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AssetId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
