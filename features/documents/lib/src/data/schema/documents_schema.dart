/// Table and column name constants for the Documents SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Notes' `NotesSchema`.
abstract final class DocumentsSchema {
  static const documentsTable = 'documents';

  static const documentId = 'document_id';
  static const documentWorkspaceId = 'workspace_id';
  static const documentTitle = 'title';
  static const documentType = 'type';
  static const documentReferenceLocation = 'reference_location';
  static const documentNotes = 'notes';
  static const documentTags = 'tags';
  static const documentStatus = 'status';
  static const documentCreatedAt = 'created_at';
  static const documentUpdatedAt = 'updated_at';
  static const documentDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> documentColumns = [
    documentId,
    documentWorkspaceId,
    documentTitle,
    documentType,
    documentReferenceLocation,
    documentNotes,
    documentTags,
    documentStatus,
    documentCreatedAt,
    documentUpdatedAt,
    documentDeletedAt,
  ];
}
