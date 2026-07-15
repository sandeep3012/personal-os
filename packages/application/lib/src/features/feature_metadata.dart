/// Immutable identity record for a feature package.
///
/// Every [FeatureModule] must provide a [FeatureMetadata] via its [metadata]
/// getter. The [FeatureRegistry] stores these records so the application shell
/// can discover and describe every loaded feature.
///
/// Example:
/// ```dart
/// const FeatureMetadata(
///   id: 'finance',
///   name: 'Finance',
///   version: '1.0.0',
///   description: 'Expense tracking, accounts, and income management.',
/// );
/// ```
final class FeatureMetadata {
  const FeatureMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
  });

  /// Unique machine-readable identifier. Use lowercase kebab-case (e.g. `'finance'`).
  final String id;

  /// Human-readable display name (e.g. `'Finance'`).
  final String name;

  /// Semantic version of this feature (e.g. `'1.0.0'`).
  final String version;

  /// Brief description of the feature's purpose.
  final String description;

  @override
  bool operator ==(Object other) =>
      other is FeatureMetadata &&
      id == other.id &&
      name == other.name &&
      version == other.version &&
      description == other.description;

  @override
  int get hashCode => Object.hash(id, name, version, description);

  @override
  String toString() =>
      'FeatureMetadata(id: $id, name: $name, version: $version)';
}
