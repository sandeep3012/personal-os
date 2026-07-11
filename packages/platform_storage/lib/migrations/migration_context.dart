/// Contextual information passed to each [Migration] step.
///
/// The concrete implementation populates this with a database handle (or any
/// other engine-specific resource) before calling [Migration.up] or
/// [Migration.down]. Migration steps use [MigrationContext] to execute SQL
/// or perform other schema changes without coupling to a concrete DB type.
///
/// Example:
/// ```dart
/// class AddUserTableMigration extends Migration {
///   const AddUserTableMigration() : super(version: 1);
///
///   @override
///   Future<void> up(MigrationContext ctx) async {
///     await ctx.execute(
///       'CREATE TABLE users (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
///     );
///   }
///
///   @override
///   Future<void> down(MigrationContext ctx) async {
///     await ctx.execute('DROP TABLE IF EXISTS users');
///   }
/// }
/// ```
abstract interface class MigrationContext {
  /// The schema version this context applies to.
  int get version;

  /// Executes a raw DDL or DML statement.
  ///
  /// Concrete implementations map this to the appropriate engine API
  /// (e.g. `database.execute(sql)` for SQLite).
  Future<void> execute(String statement);

  /// Executes a raw statement with positional [arguments].
  Future<void> executeWithArgs(String statement, List<Object?> arguments);
}
