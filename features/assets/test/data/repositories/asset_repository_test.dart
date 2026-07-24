import 'package:feature_assets/src/data/dao/asset_dao.dart';
import 'package:feature_assets/src/data/mappers/asset_mapper.dart';
import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:feature_assets/src/data/repositories/asset_repository.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dao/fake_asset_database_executor.dart';

// Mirrors Notes' note_repository_test.dart: exercises AssetRepository
// against the real AssetDao and AssetMapper, with the fake at the
// FakeAssetDatabaseExecutor boundary.

AssetRow _row({
  String id = 'asset-1',
  String workspaceId = 'ws-1',
  String name = 'Laptop',
}) {
  final now = DateTime(2024, 1, 1);
  return AssetRow(
    assetId: id,
    workspaceId: workspaceId,
    name: name,
    category: 'Electronics',
    value: 1500,
    acquisitionDate: DateTime(2024, 1, 2),
    notes: 'Work laptop',
    status: 'active',
    createdAt: now,
    updatedAt: now,
  );
}

Asset _asset({String id = 'asset-1', String workspaceId = 'ws-1'}) {
  final now = DateTime(2024, 1, 1);
  return Asset(
    id: AssetId(id),
    workspaceId: workspaceId,
    name: 'Laptop',
    category: 'Electronics',
    value: 1500,
    acquisitionDate: DateTime(2024, 1, 2),
    status: AssetStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeAssetDatabaseExecutor executor;
  late AssetRepository repository;

  setUp(() {
    executor = FakeAssetDatabaseExecutor();
    repository = AssetRepository(
      assetDao: AssetDao(executor),
      assetMapper: const AssetMapper(),
    );
  });

  group('AssetRepository.findById', () {
    test('returns a correctly mapped Asset when the row exists', () async {
      executor.queryResults.add([_row(id: 'asset-1', name: 'My Asset').toMap()]);

      final result =
          await repository.findById(const AssetId('asset-1'), workspaceId: 'ws-1');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'My Asset');
    });

    test('returns Result.success(null) when no row matches', () async {
      final result = await repository.findById(
        const AssetId('missing'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('translates a DAO failure into a AssetsException', () async {
      executor.queryError = Exception('disk read error');

      final result = await repository.findById(
        const AssetId('asset-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
      expect(result.exceptionOrNull!.message, contains('disk read error'));
    });

    test('passes through a AssetsException raised by the mapper unchanged',
        () async {
      final corruptRow = _row(id: 'asset-1').toMap();
      corruptRow['status'] = 'not_a_real_status';
      executor.queryResults.add([corruptRow]);

      final result = await repository.findById(
        const AssetId('asset-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull!.message, contains('Unrecognized status'));
    });
  });

  group('AssetRepository.findAll', () {
    test('maps all rows', () async {
      executor.queryResults.add([
        _row(id: 'asset-a', name: 'A').toMap(),
        _row(id: 'asset-b', name: 'B').toMap(),
      ]);

      final result = await repository.findAll(workspaceId: 'ws-1');

      expect(result.valueOrNull!.map((e) => e.name), ['A', 'B']);
    });

    test('returns an empty list, not a failure, when no assets exist', () async {
      final result = await repository.findAll(workspaceId: 'ws-1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });
  });

  group('AssetRepository.findByStatus', () {
    test('scopes the DAO call by status', () async {
      executor.queryResults.add([_row(id: 'asset-1').toMap()]);

      final result = await repository.findByStatus(
        AssetStatus.active,
        workspaceId: 'ws-1',
      );

      expect(executor.executedQueryArgs.single, ['ws-1', 'active']);
      expect(result.valueOrNull, hasLength(1));
    });
  });

  group('AssetRepository.search', () {
    test('maps the DAO query result into an AssetPage', () async {
      executor.queryResults.add([
        {'total': 1},
      ]);
      executor.queryResults.add([_row(id: 'asset-1').toMap()]);

      final result = await repository.search(
        const AssetQuery(workspaceId: 'ws-1'),
      );

      expect(result.valueOrNull!.totalCount, 1);
      expect(result.valueOrNull!.items, hasLength(1));
    });
  });

  group('AssetRepository.save', () {
    test('inserts a new asset when it does not already exist', () async {
      final result = await repository.save(_asset(id: 'asset-new'));

      expect(result.isSuccess, isTrue);
      final insertSql =
          executor.executedStatements.firstWhere((s) => s.contains('INSERT'));
      expect(insertSql, contains('INSERT INTO assets'));
    });

    test('updates an existing asset instead of inserting', () async {
      executor.queryResults.add([
        {'1': 1},
      ]);

      final result = await repository.save(_asset(id: 'asset-existing'));

      expect(result.isSuccess, isTrue);
      final updateSql =
          executor.executedStatements.firstWhere((s) => s.contains('UPDATE'));
      expect(updateSql, contains('UPDATE assets SET'));
    });

    test('translates a DAO failure during save', () async {
      executor.executeError = Exception('write failed');
      final result = await repository.save(_asset());
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
    });
  });

  group('AssetRepository.softDelete', () {
    test('delegates directly to AssetDao.softDelete', () async {
      final result = await repository.softDelete(
        const AssetId('asset-1'),
        workspaceId: 'ws-1',
      );

      expect(result.isSuccess, isTrue);
      final sql = executor.executedStatements.single;
      expect(sql, contains('SET deleted_at = ?'));
    });

    test('translates a DAO failure during softDelete', () async {
      executor.executeError = Exception('locked');
      final result = await repository.softDelete(
        const AssetId('asset-1'),
        workspaceId: 'ws-1',
      );
      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
    });
  });
}
