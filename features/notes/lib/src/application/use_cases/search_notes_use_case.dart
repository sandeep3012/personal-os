import 'package:application/application.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/domain/value_objects/note_page.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes a [NoteQuery] and returns a paginated [NotePage].
///
/// Delegates directly to [INoteRepository.search], which performs SQL-level
/// filtering and pagination via [NoteDao.query] — orchestration only, no
/// in-memory filtering here. Mirrors `SearchGoalsUseCase`.
final class SearchNotesUseCase implements AsyncUseCase<NoteQuery, NotePage> {
  const SearchNotesUseCase({required INoteRepository noteRepository})
      : _noteRepository = noteRepository;

  final INoteRepository _noteRepository;

  @override
  Future<Result<NotePage>> execute(NoteQuery input) =>
      _noteRepository.search(input);
}
