import 'package:feature_calendar/src/data/database/file_backed_event_database_executor.dart';
import 'package:feature_calendar/src/data/database/i_event_database_executor.dart';
import 'package:feature_calendar/src/data/database/i_event_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedEventDatabaseExecutor], persisting to disk exactly once —
/// after commit, or after a rollback restores prior state. Mirrors Notes'
/// `FileBackedNoteTransactionRunner` exactly.
final class FileBackedEventTransactionRunner implements IEventTransactionRunner {
  FileBackedEventTransactionRunner(this._executor);

  final FileBackedEventDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IEventDatabaseExecutor transactionalExecutor) action,
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
