import 'package:feature_assets/src/application/use_cases/get_asset_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

void main() {
  group('GetAssetUseCase', () {
    test('returns the asset when it exists', () async {
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
      final useCase = GetAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const GetAssetInput(assetId: AssetId('asset-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Asset');
    });

    test('fails when the asset does not exist', () async {
      final repo = FakeAssetRepository();
      final useCase = GetAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const GetAssetInput(assetId: AssetId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
    });
  });
}
