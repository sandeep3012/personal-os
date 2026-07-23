import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';

/// Records every executed statement/query and its arguments, and returns
/// pre-seeded results — mirrors Finance's `FakeFinanceDatabaseExecutor`
/// exactly.
final class FakeTaskDatabaseExecutor implements ITaskDatabaseExecutor {
  final executedQueries = <String>[];
  final executedQueryArgs = <List<Object?>>[];
  final executedStatements = <String>[];
  final executedStatementArgs = <List<Object?>>[];

  final queryResults = <List<Map<String, Object?>>>[];
  var _queryCallIndex = 0;

  var affectedRowCount = 1;

  Object? queryError;

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
