import 'package:feature_goals/src/data/database/file_backed_goal_database_executor.dart';
import 'package:feature_goals/src/data/database/i_goal_database_executor.dart';
import 'package:feature_goals/src/data/database/i_goal_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedGoalDatabaseExecutor], persisting to disk exactly once — after
/// commit, or after a rollback restores prior state. Mirrors Finance's
/// `FileBackedFinanceTransactionRunner` exactly.
final class FileBackedGoalTransactionRunner implements IGoalTransactionRunner {
  FileBackedGoalTransactionRunner(this._executor);

  final FileBackedGoalDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IGoalDatabaseExecutor transactionalExecutor) action,
  ) async {
    final snapshot = _executor.engine.snapshot();
    try {
      final result = await action(_executor.engine);
      await _executor.persist();
      return result;
    } catch (_) {
      _executor.engine.restore(snapshot);
      await _executor.persist();
      rethrow;
    }
  }
}
