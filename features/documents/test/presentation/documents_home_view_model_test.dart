import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

Document _document(
  String id, {
  DocumentStatus status = DocumentStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Document(
    id: DocumentId(id),
    workspaceId: _ws,
    title: 'Document $id',
    type: 'Contract',
    referenceLocation: 'file:///docs/test.pdf',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness() : repo = FakeDocumentRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = DocumentsHomeViewModel(
      getDocumentsUseCase: GetDocumentsUseCase(documentRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeDocumentRepository repo;
  late final WorkspaceContext workspaceContext;
  late final DocumentsHomeViewModel viewModel;
}

void main() {
  group('DocumentsHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only active documents', () async {
      final harness = _Harness()
        ..repo.seed([
          _document('a1', status: DocumentStatus.active),
          _document('a2', status: DocumentStatus.active),
          _document('a3', status: DocumentStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
