import 'package:feature_assets/src/application/use_cases/search_assets_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_query.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

Asset _asset(String id, String name, AssetStatus status) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: AssetId(id),
    workspaceId: _ws,
    name: name,
    category: 'Electronics',
    value: 100,
    acquisitionDate: DateTime(2025, 1, 1),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeAssetRepository repo;
  late SearchAssetsUseCase useCase;

  setUp(() {
    repo = FakeAssetRepository()
      ..seed([
        _asset('t1', 'Team laptop', AssetStatus.active),
        _asset('t2', 'Old server', AssetStatus.archived),
        _asset('t3', 'Team monitor', AssetStatus.active),
      ]);
    useCase = SearchAssetsUseCase(assetRepository: repo);
  });

  group('SearchAssetsUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const AssetQuery(workspaceId: _ws, status: AssetStatus.active),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by name (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const AssetQuery(workspaceId: _ws, nameContains: 'team'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const AssetQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
