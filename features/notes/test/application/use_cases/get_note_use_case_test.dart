import 'package:feature_notes/src/application/use_cases/get_note_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetNoteUseCase', () {
    test('returns the note when it exists', () async {
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
      final useCase = GetNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const GetNoteInput(noteId: NoteId('note-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Note');
    });

    test('fails when the note does not exist', () async {
      final repo = FakeNoteRepository();
      final useCase = GetNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const GetNoteInput(noteId: NoteId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
    });
  });
}
