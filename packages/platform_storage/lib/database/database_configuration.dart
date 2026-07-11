/// Immutable configuration passed to [IDatabase.open].
///
/// Technology-neutral — concrete implementations map these fields to their own
/// engine-specific config objects.
final class DatabaseConfiguration {
  const DatabaseConfiguration({
    required this.name,
    this.version = 1,
    this.path,
    this.inMemory = false,
    this.readOnly = false,
  }) : assert(version >= 1, 'Database version must be >= 1');

  /// Logical name for the database (used as the file name by most engines).
  final String name;

  /// Schema version. Must be >= 1.
  final int version;

  /// File-system path where the database file lives.
  ///
  /// If `null` the concrete implementation chooses a platform-appropriate
  /// default directory. Ignored when [inMemory] is `true`.
  final String? path;

  /// When `true` the database is created entirely in memory and no file is
  /// written to disk. Useful for tests.
  final bool inMemory;

  /// When `true` the implementation should open the database in read-only mode.
  final bool readOnly;

  @override
  String toString() => 'DatabaseConfiguration('
      'name: $name, '
      'version: $version, '
      'path: $path, '
      'inMemory: $inMemory, '
      'readOnly: $readOnly)';

  @override
  bool operator ==(Object other) =>
      other is DatabaseConfiguration &&
      name == other.name &&
      version == other.version &&
      path == other.path &&
      inMemory == other.inMemory &&
      readOnly == other.readOnly;

  @override
  int get hashCode =>
      Object.hash(name, version, path, inMemory, readOnly);
}
