import 'package:feature_calendar/src/data/database/i_event_database_executor.dart';

/// Runs a unit of work inside a single atomic database transaction. Mirrors
/// Notes' `INoteTransactionRunner` exactly.
///
/// [action] receives an [IEventDatabaseExecutor] bound to the transaction.
///
/// If [action] completes without throwing, the transaction is committed and
/// its result is returned. If [action] throws, the transaction is rolled
/// back and the error is rethrown to the caller — no partial writes are
/// retained.
abstract interface class IEventTransactionRunner {
  Future<T> runInTransaction<T>(
    Future<T> Function(IEventDatabaseExecutor transactionalExecutor) action,
  );
}
