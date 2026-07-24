/// Table and column name constants for the Notes SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Goals' `GoalsSchema`.
abstract final class NotesSchema {
  static const notesTable = 'notes';

  static const noteId = 'note_id';
  static const noteWorkspaceId = 'workspace_id';
  static const noteTitle = 'title';
  static const noteContent = 'content';
  static const noteTags = 'tags';
  static const noteStatus = 'status';
  static const noteCreatedAt = 'created_at';
  static const noteUpdatedAt = 'updated_at';
  static const noteDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> noteColumns = [
    noteId,
    noteWorkspaceId,
    noteTitle,
    noteContent,
    noteTags,
    noteStatus,
    noteCreatedAt,
    noteUpdatedAt,
    noteDeletedAt,
  ];
}
