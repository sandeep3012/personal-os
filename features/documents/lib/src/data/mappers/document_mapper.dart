import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';

/// Converts between the domain [Document] entity and the persistence
/// [DocumentRow] model. Pure conversion only — no validation, no repository
/// calls, no SQL, no business rules. Mirrors Notes' `NoteMapper`.
///
/// [Document] never represents a soft-deleted row: [DocumentDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Document] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [DocumentRow.deletedAt] to
/// `null`.
final class DocumentMapper {
  const DocumentMapper();

  /// Converts a persisted [DocumentRow] to a domain [Document].
  ///
  /// Throws [DocumentsException] if [DocumentRow.status] does not correspond
  /// to a value this mapper recognizes — corrupted or unsupported
  /// persisted data must fail loudly rather than be silently coerced.
  Document toEntity(DocumentRow row) {
    return Document(
      id: DocumentId(row.documentId),
      workspaceId: row.workspaceId,
      title: row.title,
      type: row.type,
      referenceLocation: row.referenceLocation,
      notes: row.notes,
      tags: row.tags,
      status: _statusFromColumnValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Document] to a persistable [DocumentRow].
  DocumentRow toRow(Document document) {
    return DocumentRow(
      documentId: document.id.value,
      workspaceId: document.workspaceId,
      title: document.title,
      type: document.type,
      referenceLocation: document.referenceLocation,
      notes: document.notes,
      tags: document.tags,
      status: document.status.name,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      deletedAt: null,
    );
  }

  DocumentStatus _statusFromColumnValue(String value) {
    for (final status in DocumentStatus.values) {
      if (status.name == value) return status;
    }
    throw DocumentsException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
