import 'package:feature_assets/src/application/use_cases/update_asset_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

Asset _existing({AssetStatus status = AssetStatus.active}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: const AssetId('asset-1'),
    workspaceId: _ws,
    name: 'Original name',
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
  late UpdateAssetUseCase useCase;

  setUp(() {
    repo = FakeAssetRepository()..seed([_existing()]);
    useCase = UpdateAssetUseCase(assetRepository: repo);
  });

  group('UpdateAssetUseCase', () {
    test('updates the name', () async {
      final result = await useCase.execute(
        const UpdateAssetInput(
          assetId: AssetId('asset-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.name, 'Renamed');
    });

    test('updates category and notes', () async {
      final result = await useCase.execute(
        const UpdateAssetInput(
          assetId: AssetId('asset-1'),
          workspaceId: _ws,
          category: 'Vehicle',
          notes: 'Updated notes',
        ),
      );

      expect(result.valueOrNull!.category, 'Vehicle');
      expect(result.valueOrNull!.notes, 'Updated notes');
    });

    test('updates value and acquisition date', () async {
      final result = await useCase.execute(
        UpdateAssetInput(
          assetId: const AssetId('asset-1'),
          workspaceId: _ws,
          value: 250,
          acquisitionDate: DateTime(2026, 2, 1),
        ),
      );

      expect(result.valueOrNull!.value, 250);
      expect(result.valueOrNull!.acquisitionDate, DateTime(2026, 2, 1));
    });

    test('does not change status', () async {
      final result = await useCase.execute(
        const UpdateAssetInput(
          assetId: AssetId('asset-1'),
          workspaceId: _ws,
          name: 'Renamed',
        ),
      );

      expect(result.valueOrNull!.status, AssetStatus.active);
    });

    test('fails when the asset does not exist', () async {
      final result = await useCase.execute(
        const UpdateAssetInput(
          assetId: AssetId('missing'),
          workspaceId: _ws,
          name: 'X',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.exceptionOrNull, isA<AssetsException>());
    });
  });
}
