import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_page.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Document persistence, expressed in domain terms. Mirrors
/// `INoteRepository`.
///
/// Implementations are internal to the Documents feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Notes.
abstract interface class IDocumentRepository {
  /// Returns the [Document] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted document exists.
  FutureResult<Document?> findById(DocumentId id, {required String workspaceId});

  /// Returns all non-deleted documents within [workspaceId], regardless of
  /// status — filtering by status is `SearchDocumentsUseCase`'s
  /// responsibility, not this method's.
  ///
  /// Returns an empty list when no documents exist — never fails for an empty
  /// workspace.
  FutureResult<List<Document>> findAll({required String workspaceId});

  /// Returns all non-deleted documents within [workspaceId] whose status
  /// equals [status].
  FutureResult<List<Document>> findByStatus(
    DocumentStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of documents alongside the
  /// total match count (pre-pagination). Mirrors `INoteRepository.search`.
  FutureResult<DocumentPage> search(DocumentQuery query);

  /// Persists [document]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Document document);

  /// Marks the document identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the document has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Notes).
  FutureResult<void> softDelete(DocumentId id, {required String workspaceId});
}
