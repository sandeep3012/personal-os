import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/archive_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/create_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/delete_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/application/use_cases/update_note_use_case.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'note-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeNoteRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = NotesViewModel(
      getNotesUseCase: GetNotesUseCase(noteRepository: repo),
      createNoteUseCase: CreateNoteUseCase(
        noteRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateNoteUseCase: UpdateNoteUseCase(noteRepository: repo),
      archiveNoteUseCase: ArchiveNoteUseCase(noteRepository: repo),
      deleteNoteUseCase: DeleteNoteUseCase(noteRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeNoteRepository repo;
  late final WorkspaceContext workspaceContext;
  late final NotesViewModel viewModel;
}

void main() {
  group('NotesViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no notes exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('NotesViewModel.createNote', () {
    test('creates a note starting active and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createNote(
        title: 'Groceries',
        content: 'Milk, eggs',
        tags: const ['home'],
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, NoteStatus.active);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('NotesViewModel.updateNote', () {
    test('updates the title and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createNote(title: 'Original');

      final result = await harness.viewModel.updateNote(
        noteId: created.valueOrNull!.id,
        title: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.title, 'Renamed');
    });
  });

  group('NotesViewModel.archiveNote', () {
    test('archives a note and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createNote(title: 'Note');

      final result = await harness.viewModel.archiveNote(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, NoteStatus.archived);
    });

    test('fails when the note is already archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createNote(title: 'Note');
      await harness.viewModel.archiveNote(created.valueOrNull!.id);

      final result = await harness.viewModel.archiveNote(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('NotesViewModel.deleteNote', () {
    test('soft-deletes a note and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await harness.viewModel.createNote(title: 'Note');
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final result = await harness.viewModel.deleteNote(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
