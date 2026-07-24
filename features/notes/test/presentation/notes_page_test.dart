import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/archive_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/create_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/delete_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/application/use_cases/update_note_use_case.dart';
import 'package:feature_notes/src/presentation/pages/notes_page.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_note_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'note-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeNoteRepository() {
    viewModel = NotesViewModel(
      getNotesUseCase: GetNotesUseCase(noteRepository: repo),
      createNoteUseCase: CreateNoteUseCase(
        noteRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateNoteUseCase: UpdateNoteUseCase(noteRepository: repo),
      archiveNoteUseCase: ArchiveNoteUseCase(noteRepository: repo),
      deleteNoteUseCase: DeleteNoteUseCase(noteRepository: repo),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeNoteRepository repo;
  late final NotesViewModel viewModel;

  Widget buildPage() => MaterialApp(home: NotesPage(viewModel: viewModel));
}

void main() {
  group('NotesPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no notes exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('shows a note after loading', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createNote(title: 'Groceries');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
    });
  });

  group('NotesPage — create', () {
    testWidgets('tapping the FAB opens the add-note dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Note')),
        findsOneWidget,
      );
    });

    testWidgets('creating a note adds it to the visible list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Grocery list');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Grocery list'), findsOneWidget);
    });
  });

  group('NotesPage — edit', () {
    testWidgets('tapping a note opens the edit dialog pre-filled with its title',
        (tester) async {
      final harness = _Harness();
      await harness.viewModel.createNote(title: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Note'), findsOneWidget);
    });

    testWidgets('editing the title updates the list', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createNote(title: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('NotesPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the note',
        (tester) async {
      final harness = _Harness();
      final created = await harness.viewModel.createNote(title: 'Note');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Note'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived notes are excluded from the visible list.
      expect(find.text('Note'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('NotesPage — delete', () {
    testWidgets('swiping a note away deletes it', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createNote(title: 'Note');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Note'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('NotesPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No notes yet'), findsOneWidget);

      await harness.viewModel.createNote(title: 'Newly Added');
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
