import 'package:feature_goals/src/data/database/i_goal_database_executor.dart';
import 'package:feature_goals/src/data/database/i_goal_transaction_runner.dart';
import 'package:feature_goals/src/data/database/in_memory_goal_database_executor.dart';

/// A genuinely atomic [IGoalTransactionRunner] backed by
/// [InMemoryGoalDatabaseExecutor.snapshot]/[InMemoryGoalDatabaseExecutor.restore].
/// Mirrors Finance's `InMemoryFinanceTransactionRunner` exactly.
final class InMemoryGoalTransactionRunner implements IGoalTransactionRunner {
  InMemoryGoalTransactionRunner(this._executor);

  final InMemoryGoalDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IGoalDatabaseExecutor transactionalExecutor) action,
  ) async {
    beginCount++;
    final snapshot = _executor.snapshot();
    try {
      final result = await action(_executor);
      commitCount++;
      return result;
    } catch (_) {
      _executor.restore(snapshot);
      rollbackCount++;
      rethrow;
    }
  }
}
