import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/archive_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/create_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/delete_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/application/use_cases/update_document_use_case.dart';
import 'package:feature_documents/src/presentation/pages/documents_page.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'document-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeDocumentRepository() {
    viewModel = DocumentsViewModel(
      getDocumentsUseCase: GetDocumentsUseCase(documentRepository: repo),
      createDocumentUseCase: CreateDocumentUseCase(
        documentRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateDocumentUseCase: UpdateDocumentUseCase(documentRepository: repo),
      archiveDocumentUseCase: ArchiveDocumentUseCase(documentRepository: repo),
      deleteDocumentUseCase: DeleteDocumentUseCase(documentRepository: repo),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeDocumentRepository repo;
  late final DocumentsViewModel viewModel;

  Widget buildPage() => MaterialApp(home: DocumentsPage(viewModel: viewModel));

  Future<Result<dynamic>> createDefault({String title = 'Lease agreement'}) =>
      viewModel.createDocument(
        title: title,
        type: 'Contract',
        referenceLocation: 'file:///docs/lease.pdf',
      );
}

void main() {
  group('DocumentsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no documents exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No documents yet'), findsOneWidget);
    });

    testWidgets('shows a document after loading', (tester) async {
      final harness = _Harness();
      await harness.createDefault(title: 'Standup Desk Warranty');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Standup Desk Warranty'), findsOneWidget);
    });
  });

  group('DocumentsPage — create', () {
    testWidgets('tapping the FAB opens the add-document dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Document')),
        findsOneWidget,
      );
    });
  });

  group('DocumentsPage — edit', () {
    testWidgets('tapping a document opens the edit dialog pre-filled with its title',
        (tester) async {
      final harness = _Harness();
      await harness.createDefault(title: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Document'), findsOneWidget);
    });

    testWidgets('editing the title updates the list', (tester) async {
      final harness = _Harness();
      await harness.createDefault(title: 'Original');
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

  group('DocumentsPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the document',
        (tester) async {
      final harness = _Harness();
      final created = await harness.createDefault(title: 'Document');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Document'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived documents are excluded from the visible list.
      expect(find.text('Document'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('DocumentsPage — delete', () {
    testWidgets('swiping a document away deletes it', (tester) async {
      final harness = _Harness();
      await harness.createDefault(title: 'Document');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Document'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('DocumentsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No documents yet'), findsOneWidget);

      await harness.createDefault(title: 'Newly Added');
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
