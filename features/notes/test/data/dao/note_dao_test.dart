import 'package:feature_notes/src/data/dao/note_dao.dart';
import 'package:feature_notes/src/data/models/note_query_filter.dart';
import 'package:feature_notes/src/data/models/note_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_note_database_executor.dart';

NoteRow _row({
  String id = 'note-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return NoteRow(
    noteId: id,
    workspaceId: workspaceId,
    title: 'Test Note',
    content: 'Some content',
    tags: const ['work'],
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeNoteDatabaseExecutor executor;
  late NoteDao dao;

  setUp(() {
    executor = FakeNoteDatabaseExecutor();
    dao = NoteDao(executor);
  });

  group('NoteDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO notes'));
      expect(sql, contains('note_id'));
      expect(sql, contains('status'));
    });
  });

  group('NoteDao.update', () {
    test('builds an UPDATE statement excluding note_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE notes SET'));
      expect(sql, contains('WHERE note_id = ?'));
    });
  });

  group('NoteDao.findById', () {
    test('scopes by note_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('note-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('note_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['note-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'note-1').toMap()]);
      final result = await dao.findById('note-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.noteId, 'note-1');
    });
  });

  group('NoteDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('NoteDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('NoteDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const NoteQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const NoteQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a title filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const NoteQueryFilter(workspaceId: 'ws-1', titleContains: 'meeting'),
      );

      expect(executor.executedQueries[0], contains('LOWER(title) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%meeting%');
    });

    test('adds a content filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const NoteQueryFilter(workspaceId: 'ws-1', contentContains: 'agenda'),
      );

      expect(executor.executedQueries[0], contains('LOWER(content) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%agenda%');
    });

    test('adds a tag filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const NoteQueryFilter(workspaceId: 'ws-1', tagContains: 'work'),
      );

      expect(executor.executedQueries[0], contains('LOWER(tags) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%work%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults
          .add([_row(id: 'note-a').toMap(), _row(id: 'note-b').toMap()]);

      final result = await dao.query(const NoteQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('NoteDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by note_id and workspace_id',
        () async {
      await dao.softDelete(
        'note-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'note-1', 'ws-1']),
      );
    });
  });

  group('NoteDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('note-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('note-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('note-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
