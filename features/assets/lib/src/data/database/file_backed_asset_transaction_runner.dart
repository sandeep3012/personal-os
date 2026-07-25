import 'package:feature_assets/src/data/database/file_backed_asset_database_executor.dart';
import 'package:feature_assets/src/data/database/i_asset_database_executor.dart';
import 'package:feature_assets/src/data/database/i_asset_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedAssetDatabaseExecutor], persisting to disk exactly once —
/// after commit, or after a rollback restores prior state. Mirrors Notes'
/// `FileBackedNoteTransactionRunner` exactly.
final class FileBackedAssetTransactionRunner implements IAssetTransactionRunner {
  FileBackedAssetTransactionRunner(this._executor);

  final FileBackedAssetDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IAssetDatabaseExecutor transactionalExecutor) action,
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
