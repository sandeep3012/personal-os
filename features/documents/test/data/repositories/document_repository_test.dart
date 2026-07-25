import 'package:feature_documents/src/data/dao/document_dao.dart';
import 'package:feature_documents/src/data/mappers/document_mapper.dart';
import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:feature_documents/src/data/repositories/document_repository.dart';
import 'package:feature_documents/src/domain/entities/document.dart';
import 'package:feature_documents/src/domain/exceptions/documents_exception.dart';
import 'package:feature_documents/src/domain/value_objects/document_id.dart';
import 'package:feature_documents/src/domain/value_objects/document_query.dart';
import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_document_database_executor.dart';

// Mirrors Notes' note_repository_test.dart: exercises DocumentRepository
// against the real DocumentDao and DocumentMapper, with the fake at the
// FakeDocumentDatabaseExecutor boundary.

DocumentRow _row({
  String id = 'document-1',
  String workspaceId = 'ws-1',
  String title = 'Lease agreement',
}) {
  final now = DateTime(2024, 1, 1);
  return DocumentRow(
    documentId: id,
    workspaceId: workspaceId,
    title: title,
    type: 'Contract',
    referenceLocation: 'file:///docs/lease.pdf',
    notes: 'Signed copy',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Document _document({String id = 'document-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Document(
    id: DocumentId(id),
    workspaceId: workspaceId,
    title: 'Lease agreement',
    type: 'Contract',
    referenceLocation: 'file:///docs/lease.pdf',
    status: DocumentStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeDocumentDatabaseExecutor executor;
  late DocumentRepository repository;

  setUp(() {
    executor = FakeDocumentDatabaseExecutor();
    repository = DocumentRepository(
      documentDao: DocumentDao(executor),
      documentMapper: const DocumentMapper(),
    );
  });

  group('DocumentRepository.findById', () {
    test('returns a correctly mapped Document when the row exists', () async {
      executor.queryResults.add([_row(id: 'document-1', title: 'My Document').toMap()]);

      final result =
          await repository.findById(const DocumentId('document-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.title, 'My Document');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const DocumentId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a DocumentsException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const DocumentId('document-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a DocumentsException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'document-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const DocumentId('document-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('DocumentRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'document-a', title: 'A').toMap(),
        _row(id: 'document-b', title: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((e) => e.title), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no documents exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('DocumentRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'document-1').toMap()]);

      final result = await repository.findByStatus(
        DocumentStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('DocumentRepository.search', () {
    test('maps the DAO query result into an DocumentPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'document-1').toMap()]);

      final result = await repository.search(
        const DocumentQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('DocumentRepository.save', () {
    test('inserts a new document when it does not already exist', () async {
      final result = await repository.save(_document(id: 'document-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO documents'));
    });

    test('updates an existing document instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_document(id: 'document-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE documents SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_document());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
    });
  });

  group('DocumentRepository.softDelete', () {
    test('delegates directly to DocumentDao.softDelete', () async {
      final result = await repository.softDelete(
        const DocumentId('document-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const DocumentId('document-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<DocumentsException>());
    });
  });
}
