import 'package:feature_documents/src/data/schema/documents_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `documents` table and its supporting indexes.
///
/// [Document.status] is a `TEXT` column constrained to the values of the
/// actual `DocumentStatus` enum (`active`, `archived` — see
/// `document_status.dart`). Mirrors Notes' `CreateNotesTableMigration`
/// exactly, including its current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/
/// file-backed engine rather than a real SQL engine (same as
/// Notes/Goals/Habits/Finance/Tasks/Assets today).
///
/// This table is metadata-only — [DocumentsSchema.documentReferenceLocation]
/// stores a plain string pointer (URI/path), never file bytes; real file
/// upload/blob storage is out of scope for this feature.
///
/// Soft delete is represented by nullable [DocumentsSchema.documentDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Document] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateDocumentsTableMigration extends Migration {
  const CreateDocumentsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${DocumentsSchema.documentsTable} (
        ${DocumentsSchema.documentId}          TEXT    PRIMARY KEY,
        ${DocumentsSchema.documentWorkspaceId} TEXT    NOT NULL,
        ${DocumentsSchema.documentTitle}       TEXT    NOT NULL CHECK (length(trim(${DocumentsSchema.documentTitle})) > 0),
        ${DocumentsSchema.documentType}        TEXT    NOT NULL CHECK (length(trim(${DocumentsSchema.documentType})) > 0),
        ${DocumentsSchema.documentReferenceLocation} TEXT,
        ${DocumentsSchema.documentNotes}       TEXT,
        ${DocumentsSchema.documentTags}        TEXT,
        ${DocumentsSchema.documentStatus}      TEXT    NOT NULL CHECK (${DocumentsSchema.documentStatus} IN ('active', 'archived')),
        ${DocumentsSchema.documentCreatedAt}   TEXT    NOT NULL,
        ${DocumentsSchema.documentUpdatedAt}   TEXT    NOT NULL,
        ${DocumentsSchema.documentDeletedAt}   TEXT
      )
    ''');

    // Serves IDocumentRepository.findAll(workspaceId) and general workspace
    // scoping.
    await ctx.execute('''
      CREATE INDEX idx_documents_workspace_id
      ON ${DocumentsSchema.documentsTable} (${DocumentsSchema.documentWorkspaceId})
    ''');

    // Serves IDocumentRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_documents_workspace_status
      ON ${DocumentsSchema.documentsTable} (${DocumentsSchema.documentWorkspaceId}, ${DocumentsSchema.documentStatus})
      WHERE ${DocumentsSchema.documentDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_documents_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_documents_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${DocumentsSchema.documentsTable}');
  }
}
