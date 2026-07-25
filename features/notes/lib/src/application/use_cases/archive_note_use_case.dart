import 'package:application/application.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:platform_core/platform_core.dart';

final class ArchiveNoteInput {
  const ArchiveNoteInput({
    required this.noteId,
    required this.workspaceId,
  });

  final NoteId noteId;
  final String workspaceId;
}

/// Transitions a Note to [NoteStatus.archived] from [NoteStatus.active].
///
/// Rejects (via [Note.transitionTo]) if the note is already archived —
/// mirrors `ArchiveGoalUseCase`'s pattern of failing loudly on an invalid
/// precondition rather than silently accepting a no-op.
final class ArchiveNoteUseCase implements AsyncUseCase<ArchiveNoteInput, Note> {
  const ArchiveNoteUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<Note>> execute(ArchiveNoteInput input) async {
    try {
      final findResult = await _noteRepository.findById(
        input.noteId,
        workspaceId: input.workspaceId,
      );
      if (findResult.isFailure) {
        return Result.failure(findResult.exceptionOrNull!);
      }

      final existing = findResult.valueOrNull;
      if (existing == null) {
        return Result.failure(
          NotesException(message: 'Note ${input.noteId} not found'),
        );
      }

      final archived = existing.transitionTo(
        NoteStatus.archived,
        now: DateTime.now(),
      );

      final saveResult = await _noteRepository.save(archived);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(archived);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
