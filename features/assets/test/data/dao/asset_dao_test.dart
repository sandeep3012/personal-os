import 'package:feature_assets/src/data/dao/asset_dao.dart';
import 'package:feature_assets/src/data/models/asset_query_filter.dart';
import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_asset_database_executor.dart';

AssetRow _row({
  String id = 'asset-1',
  String workspaceId = 'ws-1',
  String status = 'active',
  DateTime? deletedAt,
}) {
  final now = DateTime(2024, 1, 1);
  return AssetRow(
    assetId: id,
    workspaceId: workspaceId,
    name: 'Test Asset',
    category: 'Electronics',
    value: 1000,
    acquisitionDate: DateTime(2024, 1, 2),
    notes: 'Some notes',
    status: status,
    createdAt: now,
    updatedAt: now,
    deletedAt: deletedAt,
  );
}

void main() {
  late FakeAssetDatabaseExecutor executor;
  late AssetDao dao;

  setUp(() {
    executor = FakeAssetDatabaseExecutor();
    dao = AssetDao(executor);
  });

  group('AssetDao.insert', () {
    test('builds an INSERT statement with all columns', () async {
      await dao.insert(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('INSERT INTO assets'));
      expect(sql, contains('asset_id'));
      expect(sql, contains('status'));
    });
  });

  group('AssetDao.update', () {
    test('builds an UPDATE statement excluding asset_id from SET', () async {
      await dao.update(_row());

      final sql = executor.executedStatements.single;
      expect(sql, contains('UPDATE assets SET'));
      expect(sql, contains('WHERE asset_id = ?'));
    });
  });

  group('AssetDao.findById', () {
    test('scopes by asset_id, workspace_id, and excludes soft-deleted rows',
        () async {
      await dao.findById('asset-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('asset_id = ?'));
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('deleted_at IS NULL'));
      expect(executor.executedQueryArgs.single, ['asset-1', 'ws-1']);
    });

    test('returns null when no row matches', () async {
      final result = await dao.findById('missing', workspaceId: 'ws-1');
      expect(result, isNull);
    });

    test('maps the returned row', () async {
      executor.queryResults.add([_row(id: 'asset-1').toMap()]);
      final result = await dao.findById('asset-1', workspaceId: 'ws-1');
      expect(result, isNotNull);
      expect(result!.assetId, 'asset-1');
    });
  });

  group('AssetDao.findAll', () {
    test('scopes by workspace and orders by created_at ASC', () async {
      await dao.findAll('ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('workspace_id = ?'));
      expect(sql, contains('ORDER BY created_at ASC'));
    });
  });

  group('AssetDao.findByStatus', () {
    test('scopes by workspace and status', () async {
      await dao.findByStatus('archived', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('status = ?'));
      expect(executor.executedQueryArgs.single, ['ws-1', 'archived']);
    });
  });

  group('AssetDao.query', () {
    test('issues a COUNT query and a paginated SELECT', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(const AssetQueryFilter(workspaceId: 'ws-1'));

      expect(executor.executedQueries[0], contains('SELECT COUNT(*)'));
      expect(executor.executedQueries[1], contains('LIMIT ? OFFSET ?'));
    });

    test('adds a status filter when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const AssetQueryFilter(workspaceId: 'ws-1', status: 'active'),
      );

      expect(executor.executedQueries[0], contains('status = ?'));
    });

    test('adds a name filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const AssetQueryFilter(workspaceId: 'ws-1', nameContains: 'laptop'),
      );

      expect(executor.executedQueries[0], contains('LOWER(name) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%laptop%');
    });

    test('adds a category filter using LOWER/LIKE when provided', () async {
      executor.queryResults.add([
        {'total': 0},
      ]);
      executor.queryResults.add(const []);

      await dao.query(
        const AssetQueryFilter(workspaceId: 'ws-1', categoryContains: 'electronics'),
      );

      expect(executor.executedQueries[0], contains('LOWER(category) LIKE ?'));
      expect(executor.executedQueryArgs[0].last, '%electronics%');
    });

    test('returns totalCount and mapped items', () async {
      executor.queryResults.add([
        {'total': 2},
      ]);
      executor.queryResults
          .add([_row(id: 'asset-a').toMap(), _row(id: 'asset-b').toMap()]);

      final result = await dao.query(const AssetQueryFilter(workspaceId: 'ws-1'));

      expect(result.totalCount, 2);
      expect(result.items, hasLength(2));
    });
  });

  group('AssetDao.softDelete', () {
    test('sets deleted_at and updated_at scoped by asset_id and workspace_id',
        () async {
      await dao.softDelete(
        'asset-1',
        workspaceId: 'ws-1',
        deletedAt: DateTime(2024, 6, 1),
      );

      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?, updated_at = ?'));
      expect(
        executor.executedStatementArgs.single,
        containsAllInOrder([anything, anything, 'asset-1', 'ws-1']),
      );
    });
  });

  group('AssetDao.exists', () {
    test('issues a SELECT 1 ... LIMIT 1 query scoped by id and workspace',
        () async {
      await dao.exists('asset-1', workspaceId: 'ws-1');

      final sql = executor.executedQueries.single;
      expect(sql, contains('SELECT 1'));
      expect(sql, contains('LIMIT 1'));
    });

    test('returns true when a row is found', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);
      expect(await dao.exists('asset-1', workspaceId: 'ws-1'), isTrue);
    });

    test('returns false when no row is found', () async {
      expect(await dao.exists('asset-1', workspaceId: 'ws-1'), isFalse);
    });
  });
}
