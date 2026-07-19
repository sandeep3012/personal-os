import 'package:feature_finance/src/data/database/file_backed_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_database_executor.dart';
import 'package:feature_finance/src/data/database/i_finance_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedFinanceDatabaseExecutor], persisting to disk exactly once —
/// after commit, or after a rollback restores prior state — rather than
/// once per statement.
///
/// This matters for [ITransactionRepository.saveTransferPair]: without a
/// single end-of-transaction persist, a failure between the two legs'
/// inserts could otherwise leave a partially-written file on disk even
/// though in-memory state was correctly rolled back.
final class FileBackedFinanceTransactionRunner implements IFinanceTransactionRunner {
  FileBackedFinanceTransactionRunner(this._executor);

  final FileBackedFinanceDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IFinanceDatabaseExecutor transactionalExecutor) action,
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
