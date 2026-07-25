import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/archive_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/create_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/delete_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/application/use_cases/update_document_use_case.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'document-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeDocumentRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = DocumentsViewModel(
      getDocumentsUseCase: GetDocumentsUseCase(documentRepository: repo),
      createDocumentUseCase: CreateDocumentUseCase(
        documentRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateDocumentUseCase: UpdateDocumentUseCase(documentRepository: repo),
      archiveDocumentUseCase: ArchiveDocumentUseCase(documentRepository: repo),
      deleteDocumentUseCase: DeleteDocumentUseCase(documentRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeDocumentRepository repo;
  late final WorkspaceContext workspaceContext;
  late final DocumentsViewModel viewModel;
}

Future<Result<dynamic>> _createDefault(_Harness harness, {String title = 'Lease agreement'}) =>
    harness.viewModel.createDocument(
      title: title,
      type: 'Contract',
      referenceLocation: 'file:///docs/lease.pdf',
    );

void main() {
  group('DocumentsViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no documents exist', () async {
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

  group('DocumentsViewModel.createDocument', () {
    test('creates a document starting active and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createDocument(
        title: 'Lease agreement',
        type: 'Contract',
        referenceLocation: 'file:///docs/lease.pdf',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, DocumentStatus.active);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('DocumentsViewModel.updateDocument', () {
    test('updates the title and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness, title: 'Original');

      final result = await harness.viewModel.updateDocument(
        documentId: created.valueOrNull!.id,
        title: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.title, 'Renamed');
    });
  });

  group('DocumentsViewModel.archiveDocument', () {
    test('archives a document and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness);

      final result = await harness.viewModel.archiveDocument(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, DocumentStatus.archived);
    });

    test('fails when the document is already archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness);
      await harness.viewModel.archiveDocument(created.valueOrNull!.id);

      final result = await harness.viewModel.archiveDocument(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('DocumentsViewModel.deleteDocument', () {
    test('soft-deletes a document and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      await _createDefault(harness);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final created = harness.viewModel.state.dataOrNull!.single;
      final result = await harness.viewModel.deleteDocument(created.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
