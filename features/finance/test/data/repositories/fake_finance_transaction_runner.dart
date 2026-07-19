import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';

/// Records begin/commit/rollback counts and forwards [action] to a supplied
/// [IFinanceDatabaseExecutor] — mirrors [IFinanceTransactionRunner]'s
/// documented contract (commit on success, rollback and rethrow on failure)
/// without a real database underneath.
///
/// Since [FakeFinanceDatabaseExecutor] holds no genuine relational state,
/// "rollback" here does not undo previously-recorded statements — there is
/// nothing to undo. What this fake proves is the *orchestration* contract:
/// exactly one begin, exactly one commit XOR exactly one rollback, and the
/// original error propagating unchanged on failure.
final class FakeFinanceTransactionRunner implements IFinanceTransactionRunner {
  FakeFinanceTransactionRunner(this._executor);

  final IFinanceDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IFinanceDatabaseExecutor transactionalExecutor) action,
  ) async {
    beginCount++;
    try {
      final result = await action(_executor);
      commitCount++;
      return result;
    } catch (_) {
      rollbackCount++;
      rethrow;
    }
  }
}
