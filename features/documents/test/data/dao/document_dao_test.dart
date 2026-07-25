import 'package:feature_documents/src/data/dao/document_dao.dart';
import 'package:feature_documents/src/data/models/document_query_filter.dart';
import 'package:feature_documents/src/data/models/document_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_document_database_executor.dart';

DocumentRow _row({
  String id = 'document-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return DocumentRow(
    documentId: id,
    workspaceId: workspaceId,
    title: 'Test Document',
    type: 'Contract',
    referenceLocation: 'file:///docs/test.pdf',
    notes: 'Some notes',
    tags: const ['legal'],
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeDocumentDatabaseExecutor executor;
  late DocumentDao dao;

  setUp(() {
    executor = FakeDocumentDatabaseExecutor();
    dao = DocumentDao(executor);
  });

  group('DocumentDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO documents'));
      expect(sql, contains('document_id'));
      expect(sql, contains('status'));
    });
  });

  group('DocumentDao.update', () {
    test('builds an UPDATE statement excluding document_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE documents SET'));
      expect(sql, contains('WHERE document_id = ?'));
    });
  });

  group('DocumentDao.findById', () {
    test('scopes by document_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('document-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('document_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['document-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'document-1').toMap()]);
      final result = await dao.findById('document-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.documentId, 'document-1');
    });
  });

  group('DocumentDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('DocumentDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('DocumentDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const DocumentQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const DocumentQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a title filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const DocumentQueryFilter(workspaceId: 'ws-1', titleContains: 'lease'),
      );

      expect(executor.executedQueries[0], contains('LOWER(title) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%lease%');
    });

    test('adds a type filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const DocumentQueryFilter(workspaceId: 'ws-1', typeContains: 'contract'),
      );

      expect(executor.executedQueries[0], contains('LOWER(type) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%contract%');
    });

    test('adds a tag filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const DocumentQueryFilter(workspaceId: 'ws-1', tagContains: 'legal'),
      );

      expect(executor.executedQueries[0], contains('LOWER(tags) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%legal%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults
          .add([_row(id: 'document-a').toMap(), _row(id: 'document-b').toMap()]);

      final result = await dao.query(const DocumentQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('DocumentDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by document_id and workspace_id',
        () async {
      await dao.softDelete(
        'document-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'document-1', 'ws-1']),
      );
    });
  });

  group('DocumentDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('document-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('document-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('document-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
