import 'package:platform_core/result/result.dart';
import 'package:platform_storage/exceptions/storage_exception.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';
import 'package:platform_storage/models/migration_result.dart';

/// Orchestrates ordered execution of [Migration] steps.
///
/// Migrations are registered once via [register] and then applied by calling
/// [migrate] with a [MigrationContext] that points at the target database.
///
/// [MigrationRunner] is technology-neutral — it does not know about any
/// concrete database engine. The caller is responsible for supplying the
/// current schema version and a [MigrationContext] wired to the live
/// database connection.
///
/// ## Ordering guarantee
///
/// Migrations are always executed in ascending [Migration.version] order for
/// [migrate] (forward/up), and descending order for [rollback] (backward/down).
/// Duplicate version numbers throw a [MigrationException].
///
/// ## Example
///
/// ```dart
/// final runner = MigrationRunner()
///   ..register(CreateUsersTable())   // version 1
///   ..register(AddEmailIndex())      // version 2
///   ..register(CreateCategoriesTable()); // version 3
///
/// final result = await runner.migrate(
///   context: dbContext,
///   fromVersion: 0,
///   toVersion: 3,
/// );
/// ```
final class MigrationRunner {
  final _migrations = <int, Migration>{};

  /// Registers [migration] with this runner.
  ///
  /// Throws [MigrationException] if a migration with the same version has
  /// already been registered.
  void register(Migration migration) {
    if (_migrations.containsKey(migration.version)) {
      throw MigrationException(
        message: 'Duplicate migration version ${migration.version}. '
            'Each migration must have a unique version number.',
      );
    }
    _migrations[migration.version] = migration;
  }

  /// Returns an unmodifiable sorted view of all registered migrations.
  List<Migration> get migrations {
    final sorted = _migrations.values.toList()
      ..sort((a, b) => a.version.compareTo(b.version));
    return List.unmodifiable(sorted);
  }

  /// Applies all [Migration.up] steps whose [Migration.version] is in the
  /// range `(fromVersion, toVersion]`.
  ///
  /// Returns a [MigrationResult] describing the steps that were applied.
  ///
  /// [fromVersion] must be < [toVersion]. Returns an empty success result
  /// when the two versions are equal (already up-to-date).
  ///
  /// Wraps any exception thrown by a migration step in a [MigrationException]
  /// and returns it as [Result.failure]. Migrations already applied before
  /// the failure remain applied (partial migration).
  Future<Result<MigrationResult>> migrate({
    required MigrationContext context,
    required int fromVersion,
    required int toVersion,
  }) async {
    if (fromVersion > toVersion) {
      return Result.failure(
        MigrationException(
          message: 'fromVersion ($fromVersion) must be <= toVersion ($toVersion). '
              'Use rollback() to downgrade.',
        ),
      );
    }

    final toApply = migrations
        .where((m) => m.version > fromVersion && m.version <= toVersion)
        .toList();

    final applied = <int>[];
    for (final migration in toApply) {
      try {
        await migration.up(context);
        applied.add(migration.version);
      } catch (e, st) {
        return Result.failure(
          MigrationException(
            message: 'Migration v${migration.version} up() failed: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }

    return Result.success(
      MigrationResult(
        appliedVersions: applied,
        fromVersion: fromVersion,
        toVersion: toVersion,
        isRollback: false,
      ),
    );
  }

  /// Applies all [Migration.down] steps whose [Migration.version] is in the
  /// range `(toVersion, fromVersion]`, in descending order.
  ///
  /// Returns a [MigrationResult] describing the steps that were rolled back.
  ///
  /// [fromVersion] must be > [toVersion]. Returns an empty success result
  /// when the two versions are equal (already at target version).
  Future<Result<MigrationResult>> rollback({
    required MigrationContext context,
    required int fromVersion,
    required int toVersion,
  }) async {
    if (fromVersion < toVersion) {
      return Result.failure(
        MigrationException(
          message: 'fromVersion ($fromVersion) must be >= toVersion ($toVersion). '
              'Use migrate() to upgrade.',
        ),
      );
    }

    final toRevert = migrations
        .where((m) => m.version > toVersion && m.version <= fromVersion)
        .toList()
      ..sort((a, b) => b.version.compareTo(a.version)); // descending

    final reverted = <int>[];
    for (final migration in toRevert) {
      try {
        await migration.down(context);
        reverted.add(migration.version);
      } catch (e, st) {
        return Result.failure(
          MigrationException(
            message: 'Migration v${migration.version} down() failed: $e',
            cause: e,
            stackTrace: st,
          ),
        );
      }
    }

    return Result.success(
      MigrationResult(
        appliedVersions: reverted,
        fromVersion: fromVersion,
        toVersion: toVersion,
        isRollback: true,
      ),
    );
  }
}
