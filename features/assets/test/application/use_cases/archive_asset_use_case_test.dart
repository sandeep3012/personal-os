import 'package:feature_assets/src/application/use_cases/archive_asset_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

Asset _existing(AssetStatus status) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: const AssetId('asset-1'),
    workspaceId: _ws,
    name: 'Asset',
    category: 'Electronics',
    value: 100,
    acquisitionDate: DateTime(2025, 1, 1),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ArchiveAssetUseCase', () {
    test('archives an active asset', () async {
      final repo = FakeAssetRepository()..seed([_existing(AssetStatus.active)]);
      final useCase = ArchiveAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const ArchiveAssetInput(assetId: AssetId('asset-1'), workspaceId: _ws),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AssetStatus.archived);
    });

    test('rejects archiving an already-archived asset', () async {
      final repo = FakeAssetRepository()..seed([_existing(AssetStatus.archived)]);
      final useCase = ArchiveAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const ArchiveAssetInput(assetId: AssetId('asset-1'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
    });

    test('fails when the asset does not exist', () async {
      final repo = FakeAssetRepository();
      final useCase = ArchiveAssetUseCase(assetRepository: repo);

      final result = await useCase.execute(
        const ArchiveAssetInput(assetId: AssetId('missing'), workspaceId: _ws),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
