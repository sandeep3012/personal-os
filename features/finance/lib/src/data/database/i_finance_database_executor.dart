/// Technology-neutral SQL execution contract used by the Finance DAO layer.
///
/// `platform_storage`'s `MigrationContext` (see `platform_storage/migrations`)
/// covers DDL execution during schema migration but has no query-and-return
/// capability — it exists solely to run one-way `execute()` statements during
/// `up()`/`down()`. DAOs need to run `SELECT` statements and get rows back,
/// which no existing platform abstraction provides yet.
///
/// This interface fills exactly that gap, scoped to the Finance feature, and
/// mirrors `MigrationContext`'s shape (`execute(sql, args)`) so a future
/// concrete implementation (once a storage engine is approved via ADR) can
/// back both from the same underlying connection. It is not a competing
/// database abstraction — `IDatabase` still owns connection lifecycle;
/// this interface only adds the missing "run a statement, get rows or an
/// affected-row count" capability.
abstract interface class IFinanceDatabaseExecutor {
  /// Executes a `SELECT` statement and returns the resulting rows.
  ///
  /// [arguments] are bound positionally to `?` placeholders in [sql]. Never
  /// concatenate caller-supplied values directly into [sql].
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]);

  /// Executes an `INSERT`, `UPDATE`, or `DELETE` statement and returns the
  /// number of affected rows.
  ///
  /// [arguments] are bound positionally to `?` placeholders in [sql]. Never
  /// concatenate caller-supplied values directly into [sql].
  Future<int> execute(
    String sql, [
    List<Object?> arguments = const [],
  ]);
}
