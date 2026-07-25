import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

Note _note(String id, NoteStatus status) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: NoteId(id),
    workspaceId: _ws,
    title: 'Note $id',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetNotesUseCase', () {
    test('returns an empty list when no notes exist', () async {
      final repo = FakeNoteRepository();
      final useCase = GetNotesUseCase(noteRepository: repo);

      final result = await useCase.execute(const GetNotesInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all notes regardless of status, including archived',
        () async {
      final repo = FakeNoteRepository()
        ..seed([
          _note('t1', NoteStatus.active),
          _note('t2', NoteStatus.active),
          _note('t3', NoteStatus.archived),
        ]);
      final useCase = GetNotesUseCase(noteRepository: repo);

      final result = await useCase.execute(const GetNotesInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
