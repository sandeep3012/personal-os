import 'package:feature_documents/src/application/use_cases/archive_document_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

Document _existing(DocumentStatus status) {
  final now = DateTime(2026, 1, 1);
  return Document(
    id: const DocumentId('document-1'),
    workspaceId: _ws,
    title: 'Document',
    type: 'Contract',
    referenceLocation: 'file:///docs/test.pdf',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveDocumentUseCase', () {
    test('archives an active document', () async {
      final repo = FakeDocumentRepository()..seed([_existing(DocumentStatus.active)]);
      final useCase = ArchiveDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const ArchiveDocumentInput(documentId: DocumentId('document-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, DocumentStatus.archived);
    });

    test('rejects archiving an already-archived document', () async {
      final repo = FakeDocumentRepository()..seed([_existing(DocumentStatus.archived)]);
      final useCase = ArchiveDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const ArchiveDocumentInput(documentId: DocumentId('document-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
    });

    test('fails when the document does not exist', () async {
      final repo = FakeDocumentRepository();
      final useCase = ArchiveDocumentUseCase(documentRepository: repo);

      final result = await useCase.execute(
        const ArchiveDocumentInput(documentId: DocumentId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
