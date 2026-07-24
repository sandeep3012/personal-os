import 'package:application/application.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:platform_core/platform_core.dart';

final class DeleteNoteInput {
  const DeleteNoteInput({
    required this.noteId,
    required this.workspaceId,
  });

  final NoteId noteId;
  final String workspaceId;
}

/// Soft-deletes a Note.
///
/// No precondition beyond existence — mirrors `DeleteGoalUseCase`; Note is a
/// standalone aggregate with no cross-entity precondition.
final class DeleteNoteUseCase implements AsyncUseCase<DeleteNoteInput, void> {
  const DeleteNoteUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<void>> execute(DeleteNoteInput input) async {
    try {
      final deleteResult = await _noteRepository.softDelete(
        input.noteId,
        workspaceId: input.workspaceId,
      );
      if (deleteResult.isFailure) {
        return Result.failure(deleteResult.exceptionOrNull!);
      }

      return const Result.success(null);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
