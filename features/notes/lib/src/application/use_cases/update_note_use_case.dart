import 'package:application/application.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:platform_core/platform_core.dart';

final class UpdateNoteInput {
  const UpdateNoteInput({
    required this.noteId,
    required this.workspaceId,
    this.title,
    this.content,
    this.tags,
  });

  final NoteId noteId;
  final String workspaceId;

  /// New title. `null` keeps the existing title.
  final String? title;

  /// New content. `null` keeps the existing content.
  final String? content;

  /// New tags. `null` keeps the existing tags.
  final List<String>? tags;
}

/// Updates the mutable, non-status fields of an existing Note.
///
/// `status` is intentionally absent from [UpdateNoteInput] — status changes
/// go through [ArchiveNoteUseCase], mirroring `UpdateGoalUseCase` rejecting
/// status as an input.
final class UpdateNoteUseCase implements AsyncUseCase<UpdateNoteInput, Note> {
  const UpdateNoteUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<Note>> execute(UpdateNoteInput input) async {
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

      final updated = existing.copyWith(
        title: input.title,
        content: input.content,
        tags: input.tags,
        updatedAt: DateTime.now(),
      );

      final saveResult = await _noteRepository.save(updated);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(updated);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
