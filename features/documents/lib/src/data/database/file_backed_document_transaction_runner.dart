import 'package:feature_documents/src/data/database/file_backed_document_database_executor.dart';
import 'package:feature_documents/src/data/database/i_document_database_executor.dart';
import 'package:feature_documents/src/data/database/i_document_transaction_runner.dart';

/// Runs a unit of work directly against the in-memory engine backing
/// [FileBackedDocumentDatabaseExecutor], persisting to disk exactly once —
/// after commit, or after a rollback restores prior state. Mirrors Notes'
/// `FileBackedNoteTransactionRunner` exactly.
final class FileBackedDocumentTransactionRunner implements IDocumentTransactionRunner {
  FileBackedDocumentTransactionRunner(this._executor);

  final FileBackedDocumentDatabaseExecutor _executor;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IDocumentDatabaseExecutor transactionalExecutor) action,
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
