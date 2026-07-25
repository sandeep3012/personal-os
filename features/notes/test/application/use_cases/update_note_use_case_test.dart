import 'package:feature_notes/src/application/use_cases/update_note_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/exceptions/notes_exception.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

Note _existing({NoteStatus status = NoteStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Note(
    id: const NoteId('note-1'),
    workspaceId: _ws,
    title: 'Original title',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeNoteRepository repo;
  late UpdateNoteUseCase useCase;

  setUp(() {
    repo = FakeNoteRepository()..seed([_existing()]);
    useCase = UpdateNoteUseCase(noteRepository: repo);
  });

  group('UpdateNoteUseCase', () {
    test('updates the title', () async {
      final result = await useCase.execute(
        const UpdateNoteInput(
          noteId: NoteId('note-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Renamed');
    });

    test('updates content and tags', () async {
      final result = await useCase.execute(
        const UpdateNoteInput(
          noteId: NoteId('note-1'),
          workspaceId: _ws,
          content: 'New content',
          tags: ['work'],
        ),
      );

      expect(result.valueOrNull!.content, 'New content');
      expect(result.valueOrNull!.tags, ['work']);
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateNoteInput(
          noteId: NoteId('note-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, NoteStatus.active);
    });

    test('fails when the note does not exist', () async {
      final result = await useCase.execute(
        const UpdateNoteInput(
          noteId: NoteId('missing'),
          workspaceId: _ws,
          title: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<NotesException>());
    });
  });
}
