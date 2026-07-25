import 'package:feature_notes/src/data/database/i_note_database_executor.dart';

/// Runs a unit of work inside a single atomic database transaction. Mirrors
/// Goals' `IGoalTransactionRunner` exactly.
///
/// [action] receives an [INoteDatabaseExecutor] bound to the transaction.
///
/// If [action] completes without throwing, the transaction is committed and
/// its result is returned. If [action] throws, the transaction is rolled
/// back and the error is rethrown to the caller — no partial writes are
/// retained.
abstract interface class INoteTransactionRunner {
  Future<T> runInTransaction<T>(
    Future<T> Function(INoteDatabaseExecutor transactionalExecutor) action,
  );
}
