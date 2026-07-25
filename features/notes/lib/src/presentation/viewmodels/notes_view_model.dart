import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/archive_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/create_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/delete_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/application/use_cases/update_note_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [NotesPage]: loads all notes and exposes create/update/archive/
/// delete operations.
///
/// Depends only on use cases — never on [INoteRepository] directly. All
/// business rules (title validation, status-transition legality, etc.) are
/// enforced by the use cases and the [Note] entity beneath them; this
/// ViewModel neither duplicates nor bypasses them — it only orchestrates
/// calls and surfaces whatever [Result] they return. Mirrors
/// `GoalsViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) — this
/// ViewModel never invents or hardcodes a workspace identifier, and reloads
/// automatically when [WorkspaceContext] reports a switch.
final class NotesViewModel extends ChangeNotifier {
  NotesViewModel({
    required GetNotesUseCase getNotesUseCase,
    required CreateNoteUseCase createNoteUseCase,
    required UpdateNoteUseCase updateNoteUseCase,
    required ArchiveNoteUseCase archiveNoteUseCase,
    required DeleteNoteUseCase deleteNoteUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getNotesUseCase = getNotesUseCase,
        _createNoteUseCase = createNoteUseCase,
        _updateNoteUseCase = updateNoteUseCase,
        _archiveNoteUseCase = archiveNoteUseCase,
        _deleteNoteUseCase = deleteNoteUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetNotesUseCase _getNotesUseCase;
  final CreateNoteUseCase _createNoteUseCase;
  final UpdateNoteUseCase _updateNoteUseCase;
  final ArchiveNoteUseCase _archiveNoteUseCase;
  final DeleteNoteUseCase _deleteNoteUseCase;

  /// Reloads the note list for the newly-active workspace — presentation
  /// plumbing only, mirrors `GoalsViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Note>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with notes), or error.
  AsyncState<List<Note>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads notes for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads notes while keeping the current list visible ([isRefreshing]
  /// becomes `true` instead of resetting [state] to loading).
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final result =
        await _getNotesUseCase.execute(GetNotesInput(workspaceId: workspaceId));

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    _state = AsyncState.success(result.valueOrNull!);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Creates a new note, then reloads the list on success.
  Future<Result<Note>> createNote({
    required String title,
    String content = '',
    List<String> tags = const [],
  }) async {
    final result = await _createNoteUseCase.execute(CreateNoteInput(
      workspaceId: workspaceId,
      title: title,
      content: content,
      tags: tags,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates a note's title/content/tags, then reloads the list on success.
  /// Status is intentionally not settable here — use [archiveNote].
  Future<Result<Note>> updateNote({
    required NoteId noteId,
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final result = await _updateNoteUseCase.execute(UpdateNoteInput(
      noteId: noteId,
      workspaceId: workspaceId,
      title: title,
      content: content,
      tags: tags,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives a note, then reloads the list on success.
  Future<Result<Note>> archiveNote(NoteId noteId) async {
    final result = await _archiveNoteUseCase.execute(
      ArchiveNoteInput(noteId: noteId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes a note, then reloads the list on success.
  Future<Result<void>> deleteNote(NoteId noteId) async {
    final result = await _deleteNoteUseCase.execute(
      DeleteNoteInput(noteId: noteId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
