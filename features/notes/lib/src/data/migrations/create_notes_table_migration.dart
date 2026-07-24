import 'package:feature_notes/src/data/schema/notes_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `notes` table and its supporting indexes.
///
/// [Note.status] is a `TEXT` column constrained to the values of the actual
/// `NoteStatus` enum (`active`, `archived` — see `note_status.dart`).
/// Mirrors Goals' `CreateGoalsTableMigration` exactly, including its
/// current status: declared for parity and as schema-as-code documentation,
/// not yet wired into a runtime migration runner, since the active executor
/// is the hand-rolled in-memory/file-backed engine rather than a real SQL
/// engine (same as Goals/Finance/Tasks today).
///
/// Soft delete is represented by nullable [NotesSchema.noteDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Note] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateNotesTableMigration extends Migration {
  const CreateNotesTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${NotesSchema.notesTable} (
        ${NotesSchema.noteId}          TEXT    PRIMARY KEY,
        ${NotesSchema.noteWorkspaceId} TEXT    NOT NULL,
        ${NotesSchema.noteTitle}       TEXT    NOT NULL CHECK (length(trim(${NotesSchema.noteTitle})) > 0),
        ${NotesSchema.noteContent}     TEXT,
        ${NotesSchema.noteTags}        TEXT    NOT NULL DEFAULT '[]',
        ${NotesSchema.noteStatus}      TEXT    NOT NULL CHECK (${NotesSchema.noteStatus} IN ('active', 'archived')),
        ${NotesSchema.noteCreatedAt}   TEXT    NOT NULL,
        ${NotesSchema.noteUpdatedAt}   TEXT    NOT NULL,
        ${NotesSchema.noteDeletedAt}   TEXT
      )
    ''');

    // Serves INoteRepository.findAll(workspaceId) and general workspace
    // scoping.
    await ctx.execute('''
      CREATE INDEX idx_notes_workspace_id
      ON ${NotesSchema.notesTable} (${NotesSchema.noteWorkspaceId})
    ''');

    // Serves INoteRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_notes_workspace_status
      ON ${NotesSchema.notesTable} (${NotesSchema.noteWorkspaceId}, ${NotesSchema.noteStatus})
      WHERE ${NotesSchema.noteDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_notes_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_notes_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${NotesSchema.notesTable}');
  }
}
