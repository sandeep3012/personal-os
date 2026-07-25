import 'package:feature_goals/src/data/database/i_goal_database_executor.dart';

/// Runs a unit of work inside a single atomic database transaction. Mirrors
/// Finance's `IFinanceTransactionRunner` exactly.
///
/// [action] receives an [IGoalDatabaseExecutor] bound to the transaction.
///
/// If [action] completes without throwing, the transaction is committed and
/// its result is returned. If [action] throws, the transaction is rolled
/// back and the error is rethrown to the caller — no partial writes are
/// retained.
abstract interface class IGoalTransactionRunner {
  Future<T> runInTransaction<T>(
    Future<T> Function(IGoalDatabaseExecutor transactionalExecutor) action,
  );
}
