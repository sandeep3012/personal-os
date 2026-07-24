import 'package:feature_assets/src/data/database/i_asset_database_executor.dart';
import 'package:feature_assets/src/data/database/i_asset_transaction_runner.dart';
import 'package:feature_assets/src/data/database/in_memory_asset_database_executor.dart';

/// A genuinely atomic [IAssetTransactionRunner] backed by
/// [InMemoryAssetDatabaseExecutor.snapshot]/[InMemoryAssetDatabaseExecutor.restore].
/// Mirrors Notes' `InMemoryNoteTransactionRunner` exactly.
final class InMemoryAssetTransactionRunner implements IAssetTransactionRunner {
  InMemoryAssetTransactionRunner(this._executor);

  final InMemoryAssetDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IAssetDatabaseExecutor transactionalExecutor) action,
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
