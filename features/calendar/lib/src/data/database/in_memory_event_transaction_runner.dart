import 'package:feature_calendar/src/data/database/i_event_database_executor.dart';
import 'package:feature_calendar/src/data/database/i_event_transaction_runner.dart';
import 'package:feature_calendar/src/data/database/in_memory_event_database_executor.dart';

/// A genuinely atomic [IEventTransactionRunner] backed by
/// [InMemoryEventDatabaseExecutor.snapshot]/[InMemoryEventDatabaseExecutor.restore].
/// Mirrors Notes' `InMemoryNoteTransactionRunner` exactly.
final class InMemoryEventTransactionRunner implements IEventTransactionRunner {
  InMemoryEventTransactionRunner(this._executor);

  final InMemoryEventDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IEventDatabaseExecutor transactionalExecutor) action,
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
