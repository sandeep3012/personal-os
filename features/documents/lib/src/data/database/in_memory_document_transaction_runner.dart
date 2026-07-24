import 'package:feature_documents/src/data/database/i_document_database_executor.dart';
import 'package:feature_documents/src/data/database/i_document_transaction_runner.dart';
import 'package:feature_documents/src/data/database/in_memory_document_database_executor.dart';

/// A genuinely atomic [IDocumentTransactionRunner] backed by
/// [InMemoryDocumentDatabaseExecutor.snapshot]/[InMemoryDocumentDatabaseExecutor.restore].
/// Mirrors Notes' `InMemoryNoteTransactionRunner` exactly.
final class InMemoryDocumentTransactionRunner implements IDocumentTransactionRunner {
  InMemoryDocumentTransactionRunner(this._executor);

  final InMemoryDocumentDatabaseExecutor _executor;

  var beginCount = 0;
  var commitCount = 0;
  var rollbackCount = 0;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(IDocumentDatabaseExecutor transactionalExecutor) action,
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
