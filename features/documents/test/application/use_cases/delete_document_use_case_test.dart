import 'package:feature_documents/src/application/use_cases/delete_document_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteDocumentUseCase', () {
    test('soft-deletes an existing document', () async {
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
      final useCase = DeleteDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const DeleteDocumentInput(documentId: DocumentId('document-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent document still succeeds', () async {
      final repo = FakeDocumentRepository();
      final useCase = DeleteDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const DeleteDocumentInput(documentId: DocumentId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
