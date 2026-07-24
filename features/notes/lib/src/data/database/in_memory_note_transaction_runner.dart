import 'package:feature_notes/src/data/database/i_note_database_executor.dart';
import 'package:feature_notes/src/data/database/i_note_transaction_runner.dart';
import 'package:feature_notes/src/data/database/in_memory_note_database_executor.dart';

/// A genuinely atomic [INoteTransactionRunner] backed by
/// [InMemoryNoteDatabaseExecutor.snapshot]/[InMemoryNoteDatabaseExecutor.restore].
/// Mirrors Goals' `InMemoryGoalTransactionRunner` exactly.
final class InMemoryNoteTransactionRunner implements INoteTransactionRunner {
  InMemoryNoteTransactionRunner(this._executor);

  final InMemoryNoteDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(INoteDatabaseExecutor transactionalExecutor) action,
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
