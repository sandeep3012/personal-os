import 'package:feature_documents/src/application/use_cases/get_document_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetDocumentUseCase', () {
    test('returns the document when it exists', () async {
      final now = DateTime(2026, 1, 1);
      final document = Document(
        id: const DocumentId('document-1'),
        workspaceId: _ws,
        title: 'Document',
        type: 'Contract',
        referenceLocation: 'file:///docs/test.pdf',
        status: DocumentStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeDocumentRepository()..seed([document]);
      final useCase = GetDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const GetDocumentInput(documentId: DocumentId('document-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'Document');
    });

    test('fails when the document does not exist', () async {
      final repo = FakeDocumentRepository();
      final useCase = GetDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const GetDocumentInput(documentId: DocumentId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
    });
  });
}
