import 'package:feature_notes/src/application/use_cases/delete_note_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteNoteUseCase', () {
    test('soft-deletes an existing note', () async {
      final now = DateTime(2026, 1, 1);
      final note = Note(
        id: const NoteId('note-1'),
        workspaceId: _ws,
        title: 'Note',
        status: NoteStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeNoteRepository()..seed([note]);
      final useCase = DeleteNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const DeleteNoteInput(noteId: NoteId('note-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent note still succeeds', () async {
      final repo = FakeNoteRepository();
      final useCase = DeleteNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const DeleteNoteInput(noteId: NoteId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
