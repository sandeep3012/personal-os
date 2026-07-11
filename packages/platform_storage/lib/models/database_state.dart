/// Immutable snapshot of the current state of a managed database.
final class DatabaseState {
  const DatabaseState({
    required this.name,
    required this.version,
    required this.isOpen,
    this.path,
    this.isInMemory = false,
  });

  /// Logical name of the database.
  final String name;

  /// Current schema version.
  final int version;

  /// Whether the database connection is currently open.
  final bool isOpen;

  /// File-system path to the database file, if applicable.
  final String? path;

  /// Whether the database exists only in memory (no file on disk).
  final bool isInMemory;

  /// Returns a copy of this state with [isOpen] set to `true`.
  DatabaseState asOpen() => DatabaseState(
        name: name,
        version: version,
        isOpen: true,
        path: path,
        isInMemory: isInMemory,
      );

  /// Returns a copy of this state with [isOpen] set to `false`.
  DatabaseState asClosed() => DatabaseState(
        name: name,
        version: version,
        isOpen: false,
        path: path,
        isInMemory: isInMemory,
      );

  @override
  String toString() => 'DatabaseState('
      'name: $name, '
      'version: $version, '
      'isOpen: $isOpen, '
      'path: $path, '
      'isInMemory: $isInMemory)';

  @override
  bool operator ==(Object other) =>
      other is DatabaseState &&
      name == other.name &&
      version == other.version &&
      isOpen == other.isOpen &&
      path == other.path &&
      isInMemory == other.isInMemory;

  @override
  int get hashCode =>
      Object.hash(name, version, isOpen, path, isInMemory);
}
