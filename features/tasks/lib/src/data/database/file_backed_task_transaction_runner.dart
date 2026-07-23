import 'package:feature_tasks/src/data/database/file_backed_task_database_executor.dart';
import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';
import 'package:feature_tasks/src/data/database/i_task_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedTaskDatabaseExecutor], persisting to disk exactly once — after
/// commit, or after a rollback restores prior state. Mirrors Finance's
/// `FileBackedFinanceTransactionRunner` exactly.
final class FileBackedTaskTransactionRunner implements ITaskTransactionRunner {
  FileBackedTaskTransactionRunner(this._executor);

  final FileBackedTaskDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(ITaskDatabaseExecutor transactionalExecutor) action,
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
