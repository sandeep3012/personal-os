import 'package:feature_habits/src/data/database/file_backed_habit_database_executor.dart';
import 'package:feature_habits/src/data/database/i_habit_database_executor.dart';
import 'package:feature_habits/src/data/database/i_habit_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedHabitDatabaseExecutor], persisting to disk exactly once — after
/// commit, or after a rollback restores prior state. Mirrors Finance's
/// `FileBackedFinanceTransactionRunner` exactly.
final class FileBackedHabitTransactionRunner implements IHabitTransactionRunner {
  FileBackedHabitTransactionRunner(this._executor);

  final FileBackedHabitDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IHabitDatabaseExecutor transactionalExecutor) action,
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
