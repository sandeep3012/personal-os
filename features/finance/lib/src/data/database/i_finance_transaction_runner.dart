import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';

/// Runs a unit of work inside a single atomic database transaction.
///
/// Mirrors `platform_storage`'s `ITransactionManager.execute<T>` (commit on
/// success, rollback on any thrown error) but scoped to
/// [IFinanceDatabaseExecutor] rather than the generic `ITransaction` handle:
/// `ITransactionManager`'s `ITransaction` exposes only `commit()`/
/// `rollback()`/`isActive`, with no way to run SQL through it. DAOs in this
/// feature depend on [IFinanceDatabaseExecutor], so the transactional unit
/// of work must hand back something DAOs can actually use — an executor
/// scoped to the open transaction.
///
/// [action] receives an [IFinanceDatabaseExecutor] bound to the transaction.
/// A DAO constructed against that executor (e.g.
/// `TransactionDao(transactionalExecutor)`) participates in the same atomic
/// unit of work as any other DAO call made with it during [action].
///
/// If [action] completes without throwing, the transaction is committed and
/// its result is returned. If [action] throws, the transaction is rolled
/// back and the error is rethrown to the caller — no partial writes are
/// retained.
abstract interface class IFinanceTransactionRunner {
  Future<T> runInTransaction<T>(
    Future<T> Function(IFinanceDatabaseExecutor transactionalExecutor) action,
  );
}
