import 'package:feature_notes/src/data/database/file_backed_note_database_executor.dart';
import 'package:feature_notes/src/data/database/i_note_database_executor.dart';
import 'package:feature_notes/src/data/database/i_note_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedNoteDatabaseExecutor], persisting to disk exactly once — after
/// commit, or after a rollback restores prior state. Mirrors Goals'
/// `FileBackedGoalTransactionRunner` exactly.
final class FileBackedNoteTransactionRunner implements INoteTransactionRunner {
  FileBackedNoteTransactionRunner(this._executor);

  final FileBackedNoteDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(INoteDatabaseExecutor transactionalExecutor) action,
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
