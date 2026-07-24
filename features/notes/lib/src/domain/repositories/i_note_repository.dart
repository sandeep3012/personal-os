import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_page.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:platform_core/platform_core.dart';

/// Contract for Note persistence, expressed in domain terms. Mirrors
/// `IGoalRepository`.
///
/// Implementations are internal to the Notes feature and must never be
/// accessed directly by other features. All queries are workspace-scoped.
/// Soft-delete is the only supported removal strategy, mirroring Goals.
abstract interface class INoteRepository {
  /// Returns the [Note] with [id] within [workspaceId], or `null` if no
  /// matching, non-deleted note exists.
  FutureResult<Note?> findById(NoteId id, {required String workspaceId});

  /// Returns all non-deleted notes within [workspaceId], regardless of
  /// status — filtering by status is [SearchNotesUseCase]'s responsibility,
  /// not this method's.
  ///
  /// Returns an empty list when no notes exist — never fails for an empty
  /// workspace.
  FutureResult<List<Note>> findAll({required String workspaceId});

  /// Returns all non-deleted notes within [workspaceId] whose status equals
  /// [status].
  FutureResult<List<Note>> findByStatus(
    NoteStatus status, {
    required String workspaceId,
  });

  /// Executes [query] and returns the matching page of notes alongside the
  /// total match count (pre-pagination). Mirrors `IGoalRepository.search`.
  FutureResult<NotePage> search(NoteQuery query);

  /// Persists [note]. Creates it if it is new; updates it if it already
  /// exists.
  FutureResult<void> save(Note note);

  /// Marks the note identified by [id] as deleted within [workspaceId].
  ///
  /// Idempotent — succeeds even if the note has already been removed.
  /// Soft-delete only; hard deletion is not supported (mirrors Goals).
  FutureResult<void> softDelete(NoteId id, {required String workspaceId});
}
