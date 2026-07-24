import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

Asset _asset(String id, AssetStatus status) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: AssetId(id),
    workspaceId: _ws,
    name: 'Asset $id',
    category: 'Electronics',
    value: 100,
    acquisitionDate: DateTime(2025, 1, 1),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('GetAssetsUseCase', () {
    test('returns an empty list when no assets exist', () async {
      final repo = FakeAssetRepository();
      final useCase = GetAssetsUseCase(assetRepository: repo);

      final result = await useCase.execute(const GetAssetsInput(workspaceId: _ws));

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('returns all assets regardless of status, including archived',
        () async {
      final repo = FakeAssetRepository()
        ..seed([
          _asset('t1', AssetStatus.active),
          _asset('t2', AssetStatus.active),
          _asset('t3', AssetStatus.archived),
        ]);
      final useCase = GetAssetsUseCase(assetRepository: repo);

      final result = await useCase.execute(const GetAssetsInput(workspaceId: _ws));

      expect(result.valueOrNull, hasLength(3));
    });
  });
}
