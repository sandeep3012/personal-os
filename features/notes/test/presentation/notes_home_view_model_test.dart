import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/domain/entities/note.dart';
import 'package:feature_notes/src/domain/value_objects/note_id.dart';
import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

Note _note(String id, {NoteStatus status = NoteStatus.active}) {
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

final class _Harness {
  _Harness() : repo = FakeNoteRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = NotesHomeViewModel(
      getNotesUseCase: GetNotesUseCase(noteRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeNoteRepository repo;
  late final WorkspaceContext workspaceContext;
  late final NotesHomeViewModel viewModel;
}

void main() {
  group('NotesHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only active notes', () async {
      final harness = _Harness()
        ..repo.seed([
          _note('n1', status: NoteStatus.active),
          _note('n2', status: NoteStatus.active),
          _note('n3', status: NoteStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('archivedCount counts only archived notes', () async {
      final harness = _Harness()
        ..repo.seed([
          _note('n1', status: NoteStatus.archived),
          _note('n2', status: NoteStatus.archived),
          _note('n3', status: NoteStatus.active),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.archivedCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
