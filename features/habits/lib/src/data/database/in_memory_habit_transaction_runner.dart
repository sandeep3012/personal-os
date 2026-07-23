import 'package:feature_habits/src/data/database/i_habit_database_executor.dart';
import 'package:feature_habits/src/data/database/i_habit_transaction_runner.dart';
import 'package:feature_habits/src/data/database/in_memory_habit_database_executor.dart';

/// A genuinely atomic [IHabitTransactionRunner] backed by
/// [InMemoryHabitDatabaseExecutor.snapshot]/[InMemoryHabitDatabaseExecutor.restore].
/// Mirrors Finance's `InMemoryFinanceTransactionRunner` exactly.
final class InMemoryHabitTransactionRunner implements IHabitTransactionRunner {
  InMemoryHabitTransactionRunner(this._executor);

  final InMemoryHabitDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IHabitDatabaseExecutor transactionalExecutor) action,
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
