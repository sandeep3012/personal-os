import 'package:platform_core/result/result.dart';
import 'package:platform_storage/database/database_configuration.dart';
import 'package:platform_storage/database/database_connection.dart';
import 'package:platform_storage/exceptions/storage_exception.dart';

/// Technology-neutral contract for a local database.
///
/// Concrete implementations (Drift, Isar, SQLite, etc.) are introduced in a
/// later sprint after an ADR is approved. No implementation code should exist
/// in this package.
///
/// ## Lifecycle
///
/// ```
/// initialize(config) → open() → [use connection] → close()
///                                                  ↘ delete()
/// ```
///
/// All operations return [Result] so callers never deal with uncaught
/// [DatabaseException]s at the use-case layer.
abstract interface class IDatabase {
  /// Prepares the database engine with [configuration].
  ///
  /// Must be called once before [open]. Calling [initialize] a second time
  /// before [close] is an error.
  Future<Result<void>> initialize(DatabaseConfiguration configuration);

  /// Opens the database and returns an active [DatabaseConnection].
  ///
  /// [initialize] must be called first.
  Future<Result<DatabaseConnection>> open();

  /// Closes the current [DatabaseConnection].
  ///
  /// Safe to call when the database is already closed.
  Future<Result<void>> close();

  /// Permanently deletes the database file (or clears memory for in-memory
  /// databases). The database must be closed before calling [delete].
  Future<Result<void>> delete();

  /// Whether a database connection is currently open.
  bool get isOpen;
}
