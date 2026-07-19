/// Opaque reference to a category owned by the platform Classification Service.
///
/// Finance never performs category CRUD. This value is stored and passed
/// through as received; Finance never interprets its structure.
final class CategoryId {
  const CategoryId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CategoryId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
