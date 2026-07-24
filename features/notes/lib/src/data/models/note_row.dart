import 'package:feature_notes/src/data/schema/notes_schema.dart';

/// A single, unmapped row from the `notes` table.
///
/// [NoteRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Note` entity.
/// Mapping between [NoteRow] and `Note` is a repository-layer concern, not a
/// DAO concern. Mirrors Goals' `GoalRow`.
///
/// [tags] is persisted as a single delimited `TEXT` column (pipe-separated,
/// e.g. `|work|urgent|`) rather than a normalized child table — Notes has no
/// approved multi-table storage engine yet (same status as Goals/Habits'
/// single-table in-memory engine), and tag filtering only ever needs a
/// substring `LIKE` match (see [NoteQueryFilter.tagContains]), which a
/// delimited column supports directly.
final class NoteRow {
  const NoteRow({
    required this.noteId,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.content = '',
    this.tags = const [],
    this.deletedAt,
  });

  final String noteId;
  final String workspaceId;
  final String title;
  final String content;
  final List<String> tags;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  static const _tagDelimiter = '|';

  /// Builds a [NoteRow] from a raw SQL result row.
  factory NoteRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[NotesSchema.noteDeletedAt] as String?;
    return NoteRow(
      noteId: map[NotesSchema.noteId]! as String,
      workspaceId: map[NotesSchema.noteWorkspaceId]! as String,
      title: map[NotesSchema.noteTitle]! as String,
      content: map[NotesSchema.noteContent] as String? ?? '',
      tags: _decodeTags(map[NotesSchema.noteTags] as String?),
      status: map[NotesSchema.noteStatus]! as String,
      createdAt: DateTime.parse(map[NotesSchema.noteCreatedAt]! as String),
      updatedAt: DateTime.parse(map[NotesSchema.noteUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [NotesSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        NotesSchema.noteId: noteId,
        NotesSchema.noteWorkspaceId: workspaceId,
        NotesSchema.noteTitle: title,
        NotesSchema.noteContent: content,
        NotesSchema.noteTags: _encodeTags(tags),
        NotesSchema.noteStatus: status,
        NotesSchema.noteCreatedAt: createdAt.toIso8601String(),
        NotesSchema.noteUpdatedAt: updatedAt.toIso8601String(),
        NotesSchema.noteDeletedAt: deletedAt?.toIso8601String(),
      };

  static String _encodeTags(List<String> tags) =>
      tags.isEmpty ? '' : '$_tagDelimiter${tags.join(_tagDelimiter)}$_tagDelimiter';

  static List<String> _decodeTags(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(_tagDelimiter)
        .where((segment) => segment.isNotEmpty)
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.noteId == noteId &&
          other.workspaceId == workspaceId &&
          other.title == title &&
          other.content == content &&
          _listEquals(other.tags, tags) &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        noteId,
        workspaceId,
        title,
        content,
        Object.hashAll(tags),
        status,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'NoteRow(noteId: $noteId, title: $title)';
}
