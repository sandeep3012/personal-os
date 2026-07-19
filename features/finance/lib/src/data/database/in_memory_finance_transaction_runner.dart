import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';
import 'package:feature_finance/src/data/database/in_memory_finance_database_executor.dart';

/// A genuinely atomic [IFinanceTransactionRunner] backed by
/// [InMemoryFinanceDatabaseExecutor.snapshot]/[InMemoryFinanceDatabaseExecutor.restore].
///
/// Pairs with [InMemoryFinanceDatabaseExecutor] as the Finance feature's
/// default persistence until a concrete storage engine is approved via ADR.
/// It takes a real snapshot of table state before running [action] and
/// restores it on failure — so a rolled-back transfer genuinely leaves no
/// rows behind, provable by querying the executor afterward.
final class InMemoryFinanceTransactionRunner implements IFinanceTransactionRunner {
  InMemoryFinanceTransactionRunner(this._executor);

  final InMemoryFinanceDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IFinanceDatabaseExecutor transactionalExecutor) action,
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
