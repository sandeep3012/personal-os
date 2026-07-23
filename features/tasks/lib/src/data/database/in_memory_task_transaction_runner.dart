import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';
import 'package:feature_tasks/src/data/database/i_task_transaction_runner.dart';
import 'package:feature_tasks/src/data/database/in_memory_task_database_executor.dart';

/// A genuinely atomic [ITaskTransactionRunner] backed by
/// [InMemoryTaskDatabaseExecutor.snapshot]/[InMemoryTaskDatabaseExecutor.restore].
/// Mirrors Finance's `InMemoryFinanceTransactionRunner` exactly.
final class InMemoryTaskTransactionRunner implements ITaskTransactionRunner {
  InMemoryTaskTransactionRunner(this._executor);

  final InMemoryTaskDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(ITaskDatabaseExecutor transactionalExecutor) action,
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
