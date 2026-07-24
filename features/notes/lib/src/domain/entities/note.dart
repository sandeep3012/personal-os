import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';

/// A Note aggregate root — a single, standalone piece of free-form text a
/// user has written down (mirrors Goals' standalone-aggregate shape). There
/// is no owning Notebook/Folder entity; grouping, if ever introduced,
/// happens through the platform Entity Linking Service, not through a field
/// on this entity.
///
/// Business invariants enforced here:
/// - [title] must not be empty and must not exceed 200 characters (mirrors
///   Goal/Task/Habit's title invariant).
/// - [content] must not exceed 20,000 characters.
/// - [tags] entries are never empty strings and never duplicated (case
///   sensitive) — enforced by normalizing on construction.
/// - Status transitions are only permitted per the approved transition table
///   — enforced by [transitionTo], not by direct field mutation (this class
///   has no public status setter).
final class Note {
  Note({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.content = '',
    List<String> tags = const [],
  }) : tags = _normalizeTags(tags) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const NotesException(message: 'Note title must not be empty');
    }
    if (title.length > 200) {
      throw const NotesException(
        message: 'Note title must not exceed 200 characters',
      );
    }
    if (content.length > 20000) {
      throw const NotesException(
        message: 'Note content must not exceed 20000 characters',
      );
    }
  }

  final NoteId id;
  final String workspaceId;
  final String title;

  /// The free-form body of the note. Defaults to an empty string — a Note
  /// may be title-only.
  final String content;

  /// Free-text labels attached to this note. Never contains empty strings
  /// or duplicates (case sensitive) — see [_normalizeTags].
  final List<String> tags;

  final NoteStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  static List<String> _normalizeTags(List<String> tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final rawTag in tags) {
      final tag = rawTag.trim();
      if (tag.isEmpty) continue;
      if (seen.add(tag)) result.add(tag);
    }
    return List.unmodifiable(result);
  }

  /// Returns a copy of this note with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes.
  /// Mirrors `Goal.copyWith` rejecting status as an updatable field.
  Note copyWith({
    String? title,
    String? content,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id,
        workspaceId: workspaceId,
        title: title ?? this.title,
        content: content ?? this.content,
        tags: tags ?? this.tags,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this note transitioned to [next].
  ///
  /// Throws [NotesException] if [next] is not reachable from [status] per
  /// the approved transition table:
  ///
  /// ```
  /// active   -> archived
  /// archived -> (none — terminal)
  /// ```
  Note transitionTo(NoteStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw NotesException(
        message: 'Cannot transition Note from ${status.name} to ${next.name}',
      );
    }
    return Note(
      id: id,
      workspaceId: workspaceId,
      title: title,
      content: content,
      tags: tags,
      status: next,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Note && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Note(id: $id, title: $title, status: ${status.name})';
}
