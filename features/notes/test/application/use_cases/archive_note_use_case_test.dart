import 'package:feature_notes/src/application/use_cases/archive_note_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

Note _existing(NoteStatus status) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: const NoteId('note-1'),
    workspaceId: _ws,
    title: 'Note',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveNoteUseCase', () {
    test('archives an active note', () async {
      final repo = FakeNoteRepository()..seed([_existing(NoteStatus.active)]);
      final useCase = ArchiveNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const ArchiveNoteInput(noteId: NoteId('note-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, NoteStatus.archived);
    });

    test('rejects archiving an already-archived note', () async {
      final repo = FakeNoteRepository()..seed([_existing(NoteStatus.archived)]);
      final useCase = ArchiveNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const ArchiveNoteInput(noteId: NoteId('note-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
    });

    test('fails when the note does not exist', () async {
      final repo = FakeNoteRepository();
      final useCase = ArchiveNoteUseCase(noteRepository: repo);

      final result = await useCase.execute(
        const ArchiveNoteInput(noteId: NoteId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
