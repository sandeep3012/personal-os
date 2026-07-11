/// Immutable record of the outcome of a [MigrationRunner] run.
final class MigrationResult {
  const MigrationResult({
    required this.appliedVersions,
    required this.fromVersion,
    required this.toVersion,
    required this.isRollback,
  });

  /// The version numbers of all migrations that were successfully applied
  /// (in execution order — ascending for forward migrations, descending for
  /// rollbacks).
  final List<int> appliedVersions;

  /// The schema version before the migration run.
  final int fromVersion;

  /// The intended target schema version.
  final int toVersion;

  /// `true` if this result describes a rollback, `false` for a forward
  /// migration.
  final bool isRollback;

  /// Whether any migrations were actually applied.
  bool get hadChanges => appliedVersions.isNotEmpty;

  /// The number of migration steps applied.
  int get stepCount => appliedVersions.length;

  @override
  String toString() => 'MigrationResult('
      'from: $fromVersion, '
      'to: $toVersion, '
      'isRollback: $isRollback, '
      'applied: $appliedVersions)';

  @override
  bool operator ==(Object other) =>
      other is MigrationResult &&
      fromVersion == other.fromVersion &&
      toVersion == other.toVersion &&
      isRollback == other.isRollback &&
      _listEquals(appliedVersions, other.appliedVersions);

  @override
  int get hashCode =>
      Object.hash(fromVersion, toVersion, isRollback, Object.hashAll(appliedVersions));

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
