import 'package:feature_notes/src/application/use_cases/search_notes_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_query.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

Note _note(String id, String title, NoteStatus status) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: NoteId(id),
    workspaceId: _ws,
    title: title,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeNoteRepository repo;
  late SearchNotesUseCase useCase;

  setUp(() {
    repo = FakeNoteRepository()
      ..seed([
        _note('t1', 'Grocery list', NoteStatus.active),
        _note('t2', 'Read a book', NoteStatus.archived),
        _note('t3', 'Grocery ideas', NoteStatus.active),
      ]);
    useCase = SearchNotesUseCase(noteRepository: repo);
  });

  group('SearchNotesUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const NoteQuery(workspaceId: _ws, status: NoteStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by title (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const NoteQuery(workspaceId: _ws, titleContains: 'grocery'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const NoteQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
