import 'package:application/application.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:platform_core/platform_core.dart';

final class GetNotesInput {
  const GetNotesInput({required this.workspaceId});

  final String workspaceId;
}

/// Returns all non-deleted notes in the workspace, regardless of status —
/// filtering by status is [SearchNotesUseCase]'s job. Mirrors
/// `GetGoalsUseCase` in shape.
final class GetNotesUseCase implements AsyncUseCase<GetNotesInput, List<Note>> {
  const GetNotesUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<List<Note>>> execute(GetNotesInput input) async {
    try {
      final result =
          await _noteRepository.findAll(workspaceId: input.workspaceId);
      if (result.isFailure) return Result.failure(result.exceptionOrNull!);

      return Result.success(result.valueOrNull!);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
