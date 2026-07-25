import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';

/// Converts between the domain [Note] entity and the persistence [NoteRow]
/// model. Pure conversion only — no validation, no repository calls, no SQL,
/// no business rules. Mirrors Goals' `GoalMapper`.
///
/// [Note] never represents a soft-deleted row: [NoteDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Note] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [NoteRow.deletedAt] to
/// `null`.
final class NoteMapper {
  const NoteMapper();

  /// Converts a persisted [NoteRow] to a domain [Note].
  ///
  /// Throws [NotesException] if [NoteRow.status] does not correspond to a
  /// value this mapper recognizes — corrupted or unsupported persisted data
  /// must fail loudly rather than be silently coerced.
  Note toEntity(NoteRow row) {
    return Note(
      id: NoteId(row.noteId),
      workspaceId: row.workspaceId,
      title: row.title,
      content: row.content,
      tags: row.tags,
      status: _statusFromColumnValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Note] to a persistable [NoteRow].
  NoteRow toRow(Note note) {
    return NoteRow(
      noteId: note.id.value,
      workspaceId: note.workspaceId,
      title: note.title,
      content: note.content,
      tags: note.tags,
      status: note.status.name,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      deletedAt: null,
    );
  }

  NoteStatus _statusFromColumnValue(String value) {
    for (final status in NoteStatus.values) {
      if (status.name == value) return status;
    }
    throw NotesException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
