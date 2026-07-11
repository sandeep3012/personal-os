import 'package:platform_storage/migrations/migration_context.dart';

/// A single, versioned schema change.
///
/// Each [Migration] has a strictly monotonically-increasing [version] that
/// uniquely identifies it. [MigrationRunner] applies migrations in ascending
/// [version] order during [up] and descending order during [down].
///
/// Migrations must be deterministic — running the same migration twice on the
/// same schema must produce the same result (idempotent DDL recommended).
///
/// Example:
/// ```dart
/// class CreateCategoriesTable extends Migration {
///   const CreateCategoriesTable() : super(version: 2);
///
///   @override
///   Future<void> up(MigrationContext ctx) async {
///     await ctx.execute('''
///       CREATE TABLE categories (
///         id   TEXT PRIMARY KEY,
///         name TEXT NOT NULL
///       )
///     ''');
///   }
///
///   @override
///   Future<void> down(MigrationContext ctx) async {
///     await ctx.execute('DROP TABLE IF EXISTS categories');
///   }
/// }
/// ```
abstract class Migration {
  const Migration({required this.version})
      : assert(version >= 1, 'Migration version must be >= 1');

  /// Strictly monotonically-increasing version identifier.
  ///
  /// [MigrationRunner] sorts by this value — duplicate versions throw a
  /// [MigrationException].
  final int version;

  /// Applies this migration (schema upgrade path).
  ///
  /// Called by [MigrationRunner] when upgrading to [version].
  Future<void> up(MigrationContext ctx);

  /// Reverts this migration (schema downgrade path).
  ///
  /// Called by [MigrationRunner] when downgrading past [version]. Providing a
  /// meaningful [down] implementation is strongly recommended for all
  /// production migrations to support rollbacks.
  Future<void> down(MigrationContext ctx);

  @override
  String toString() => 'Migration(version: $version)';
}
