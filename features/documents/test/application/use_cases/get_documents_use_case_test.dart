import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

Document _document(String id, DocumentStatus status) {
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

void main() {
  group('GetDocumentsUseCase', () {
    test('returns an empty list when no documents exist', () async {
      final repo = FakeDocumentRepository();
      final useCase = GetDocumentsUseCase(documentRepository: repo);

      final result = await useCase.execute(const GetDocumentsInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all documents regardless of status, including archived',
        () async {
      final repo = FakeDocumentRepository()
        ..seed([
          _document('t1', DocumentStatus.active),
          _document('t2', DocumentStatus.active),
          _document('t3', DocumentStatus.archived),
        ]);
      final useCase = GetDocumentsUseCase(documentRepository: repo);

      final result = await useCase.execute(const GetDocumentsInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
