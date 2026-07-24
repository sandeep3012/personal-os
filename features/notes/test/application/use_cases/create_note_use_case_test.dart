import 'package:feature_notes/src/application/use_cases/create_note_use_case.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

final class _FixedId implements IdGenerator {
  @override
  String generate() => 'note-1';
}

void main() {
  group('CreateNoteUseCase', () {
    test('creates a note starting active', () async {
      final repo = FakeNoteRepository();
      final useCase = CreateNoteUseCase(noteRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateNoteInput(workspaceId: _ws, title: 'My note'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, NoteStatus.active);
      expect(result.valueOrNull!.title, 'My note');
      expect(repo.store, hasLength(1));
    });

    test('creates a note with content and tags', () async {
      final repo = FakeNoteRepository();
      final useCase = CreateNoteUseCase(noteRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateNoteInput(
          workspaceId: _ws,
          title: 'My note',
          content: 'Some body text',
          tags: ['work', 'ideas'],
        ),
      );

      expect(result.valueOrNull!.content, 'Some body text');
      expect(result.valueOrNull!.tags, ['work', 'ideas']);
    });

    test('rejects an empty title', () async {
      final repo = FakeNoteRepository();
      final useCase = CreateNoteUseCase(noteRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateNoteInput(workspaceId: _ws, title: '   '),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
