import 'package:feature_documents/src/application/use_cases/update_document_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

Document _existing({DocumentStatus status = DocumentStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Document(
    id: const DocumentId('document-1'),
    workspaceId: _ws,
    title: 'Original title',
    type: 'Contract',
    referenceLocation: 'file:///docs/test.pdf',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeDocumentRepository repo;
  late UpdateDocumentUseCase useCase;

  setUp(() {
    repo = FakeDocumentRepository()..seed([_existing()]);
    useCase = UpdateDocumentUseCase(documentRepository: repo);
  });

  group('UpdateDocumentUseCase', () {
    test('updates the title', () async {
      final result = await useCase.execute(
        const UpdateDocumentInput(
          documentId: DocumentId('document-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Renamed');
    });

    test('updates type and notes', () async {
      final result = await useCase.execute(
        const UpdateDocumentInput(
          documentId: DocumentId('document-1'),
          workspaceId: _ws,
          type: 'Receipt',
          notes: 'Updated notes',
        ),
      );

      expect(result.valueOrNull!.type, 'Receipt');
      expect(result.valueOrNull!.notes, 'Updated notes');
    });

    test('updates referenceLocation and tags', () async {
      final result = await useCase.execute(
        const UpdateDocumentInput(
          documentId: DocumentId('document-1'),
          workspaceId: _ws,
          referenceLocation: 'file:///docs/updated.pdf',
          tags: ['legal', 'home'],
        ),
      );

      expect(result.valueOrNull!.referenceLocation, 'file:///docs/updated.pdf');
      expect(result.valueOrNull!.tags, ['legal', 'home']);
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateDocumentInput(
          documentId: DocumentId('document-1'),
          workspaceId: _ws,
          title: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, DocumentStatus.active);
    });

    test('fails when the document does not exist', () async {
      final result = await useCase.execute(
        const UpdateDocumentInput(
          documentId: DocumentId('missing'),
          workspaceId: _ws,
          title: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
    });
  });
}
