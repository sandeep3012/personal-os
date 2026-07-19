import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';

/// Records every executed statement/query and its arguments, and returns
/// pre-seeded results — mirrors the same recording-fake pattern used for
/// `MigrationContext` in the schema migration tests (see
/// `test/data/migrations/fake_migration_context.dart`).
///
/// This asserts that DAOs build the *correct SQL and parameter list* — the
/// same boundary the migration tests already validate for DDL. It does not
/// execute real SQL; genuine query execution is exercised once a concrete
/// [IFinanceDatabaseExecutor] implementation exists (deferred pending an
/// ADR on the storage engine, same as `IDatabase`).
final class FakeFinanceDatabaseExecutor implements IFinanceDatabaseExecutor {
  final executedQueries = <String>[];
  final executedQueryArgs = <List<Object?>>[];
  final executedStatements = <String>[];
  final executedStatementArgs = <List<Object?>>[];

  /// Rows returned by successive [query] calls, consumed in order. If more
  /// calls are made than results were queued, an empty list is returned.
  final queryResults = <List<Map<String, Object?>>>[];
  var _queryCallIndex = 0;

  /// The affected-row count returned by every [execute] call.
  var affectedRowCount = 1;

  /// When set, [query] throws this instead of returning a result — used by
  /// repository-layer tests to verify DAO-failure translation.
  Object? queryError;

  /// When set, [execute] throws this instead of returning a result — used by
  /// repository-layer tests to verify DAO-failure translation.
  ///
  /// If [executeErrorOnCallIndex] is also set, the error is thrown only on
  /// that (0-based) call to [execute]; otherwise it throws on every call —
  /// used to simulate a failure partway through a multi-statement operation
  /// (e.g. the second insert of a transfer pair).
  Object? executeError;
  int? executeErrorOnCallIndex;
  var _executeCallIndex = 0;

  @override
  Future<List<Map<String, Object?>>> query(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    if (queryError != null) throw queryError!;
    executedQueries.add(sql);
    executedQueryArgs.add(arguments);
    if (_queryCallIndex < queryResults.length) {
      return queryResults[_queryCallIndex++];
    }
    return const [];
  }

  @override
  Future<int> execute(
    String sql, [
    List<Object?> arguments = const [],
  ]) async {
    final callIndex = _executeCallIndex++;
    final shouldThrow = executeError != null &&
        (executeErrorOnCallIndex == null || executeErrorOnCallIndex == callIndex);
    if (shouldThrow) throw executeError!;
    executedStatements.add(sql);
    executedStatementArgs.add(arguments);
    return affectedRowCount;
  }
}
