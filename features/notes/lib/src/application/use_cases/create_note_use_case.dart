import 'package:application/application.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:platform_core/platform_core.dart';

final class CreateNoteInput {
  const CreateNoteInput({
    required this.workspaceId,
    required this.title,
    this.content = '',
    this.tags = const [],
  });

  final String workspaceId;
  final String title;
  final String content;
  final List<String> tags;
}

/// Creates a new Note and persists it via [INoteRepository].
///
/// New notes always start at [NoteStatus.active] — mirrors
/// `CreateGoalUseCase` in shape. All validation (title non-empty/length,
/// content length, tag normalization) is enforced by the [Note] entity
/// constructor itself — this use case performs no additional validation.
final class CreateNoteUseCase implements AsyncUseCase<CreateNoteInput, Note> {
  CreateNoteUseCase({
    required INoteRepository noteRepository,
    required IdGenerator idGenerator,
  })  : _noteRepository = noteRepository,
        _idGenerator = idGenerator;

  final INoteRepository _noteRepository;
  final IdGenerator _idGenerator;

  @override
  Future<Result<Note>> execute(CreateNoteInput input) async {
    try {
      final now = DateTime.now();
      final note = Note(
        id: NoteId(_idGenerator.generate()),
        workspaceId: input.workspaceId,
        title: input.title,
        content: input.content,
        tags: input.tags,
        status: NoteStatus.active,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await _noteRepository.save(note);
      if (saveResult.isFailure) {
        return Result.failure(saveResult.exceptionOrNull!);
      }

      return Result.success(note);
    } on AppException catch (e) {
      return Result.failure(e);
    }
  }
}
