import 'package:feature_documents/src/application/use_cases/create_document_use_case.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../../helpers/fake_document_repository.dart';

const _ws = 'ws-1';

final class _FixedId implements IdGenerator {
  @override
  String generate() => 'document-1';
}

void main() {
  group('CreateDocumentUseCase', () {
    test('creates a document starting active', () async {
      final repo = FakeDocumentRepository();
      final useCase = CreateDocumentUseCase(documentRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateDocumentInput(
          workspaceId: _ws,
          title: 'Lease agreement',
          type: 'Contract',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, DocumentStatus.active);
      expect(result.valueOrNull!.title, 'Lease agreement');
      expect(repo.store, hasLength(1));
    });

    test('creates a document with notes and tags', () async {
      final repo = FakeDocumentRepository();
      final useCase = CreateDocumentUseCase(documentRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateDocumentInput(
          workspaceId: _ws,
          title: 'Lease agreement',
          type: 'Contract',
          notes: 'Signed copy',
          tags: ['legal', 'home'],
        ),
      );

      expect(result.valueOrNull!.notes, 'Signed copy');
      expect(result.valueOrNull!.tags, ['legal', 'home']);
    });

    test('rejects an empty title', () async {
      final repo = FakeDocumentRepository();
      final useCase = CreateDocumentUseCase(documentRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateDocumentInput(
          workspaceId: _ws,
          title: '   ',
          type: 'Contract',
        ),
      );

      expect(result.isFailure, isTrue);
    });

    test('rejects an empty type', () async {
      final repo = FakeDocumentRepository();
      final useCase = CreateDocumentUseCase(documentRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        const CreateDocumentInput(
          workspaceId: _ws,
          title: 'Lease agreement',
          type: '   ',
        ),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
