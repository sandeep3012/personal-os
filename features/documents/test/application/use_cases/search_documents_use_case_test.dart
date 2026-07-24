import 'package:feature_documents/src/application/use_cases/search_documents_use_case.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

Document _document(String id, String name, DocumentStatus status) {
  final now = DateTime(2026, 1, 1);
  return Document(
    id: DocumentId(id),
    workspaceId: _ws,
    title: name,
    type: 'Contract',
    referenceLocation: 'file:///docs/test.pdf',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeDocumentRepository repo;
  late SearchDocumentsUseCase useCase;

  setUp(() {
    repo = FakeDocumentRepository()
      ..seed([
        _document('t1', 'Team laptop', DocumentStatus.active),
        _document('t2', 'Old server', DocumentStatus.archived),
        _document('t3', 'Team monitor', DocumentStatus.active),
      ]);
    useCase = SearchDocumentsUseCase(documentRepository: repo);
  });

  group('SearchDocumentsUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const DocumentQuery(workspaceId: _ws, status: DocumentStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by title (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const DocumentQuery(workspaceId: _ws, titleContains: 'team'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const DocumentQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
