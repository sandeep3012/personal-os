import 'package:feature_assets/src/application/use_cases/delete_asset_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

void main() {
  group('DeleteAssetUseCase', () {
    test('soft-deletes an existing asset', () async {
      final now = DateTime(2026, 1, 1);
      final asset = Asset(
        id: const AssetId('asset-1'),
        workspaceId: _ws,
        name: 'Asset',
        category: 'Electronics',
        value: 100,
        acquisitionDate: DateTime(2025, 1, 1),
        status: AssetStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      final repo = FakeAssetRepository()..seed([asset]);
      final useCase = DeleteAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const DeleteAssetInput(assetId: AssetId('asset-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(repo.store, isEmpty);
    });

    test('is idempotent — deleting a nonexistent asset still succeeds', () async {
      final repo = FakeAssetRepository();
      final useCase = DeleteAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const DeleteAssetInput(assetId: AssetId('missing'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
