import 'package:application/application.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:platform_core/platform_core.dart';

final class GetNoteInput {
  const GetNoteInput({required this.noteId, required this.workspaceId});

  final NoteId noteId;
  final String workspaceId;
}

/// Returns a single Note by id. Mirrors `GetGoalUseCase`.
final class GetNoteUseCase implements AsyncUseCase<GetNoteInput, Note> {
  const GetNoteUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<Note>> execute(GetNoteInput input) async {
    try {
      final result = await _noteRepository.findById(
        input.noteId,
        workspaceId: input.workspaceId,
      );
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      final note = result.valueOrNull;
      if (note == null) {
        return Result.failure(
          NotesException(message: 'Note ${input.noteId} not found'),
        );
      }

      return Result.success(note);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
