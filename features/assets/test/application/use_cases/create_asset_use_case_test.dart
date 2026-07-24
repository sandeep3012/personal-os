import 'package:feature_assets/src/application/use_cases/create_asset_use_case.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

final class _FixedId implements IdGenerator {
  @override
  String generate() => 'asset-1';
}

void main() {
  group('CreateAssetUseCase', () {
    test('creates an asset starting active', () async {
      final repo = FakeAssetRepository();
      final useCase = CreateAssetUseCase(assetRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateAssetInput(
          workspaceId: _ws,
          name: 'Laptop',
          category: 'Electronics',
          value: 1500,
          acquisitionDate: DateTime(2026, 1, 1),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AssetStatus.active);
      expect(result.valueOrNull!.name, 'Laptop');
      expect(repo.store, hasLength(1));
    });

    test('creates an asset with notes', () async {
      final repo = FakeAssetRepository();
      final useCase = CreateAssetUseCase(assetRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateAssetInput(
          workspaceId: _ws,
          name: 'Laptop',
          category: 'Electronics',
          value: 1500,
          acquisitionDate: DateTime(2026, 1, 1),
          notes: 'Work laptop',
        ),
      );

      expect(result.valueOrNull!.notes, 'Work laptop');
    });

    test('rejects an empty name', () async {
      final repo = FakeAssetRepository();
      final useCase = CreateAssetUseCase(assetRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateAssetInput(
          workspaceId: _ws,
          name: '   ',
          category: 'Electronics',
          value: 1500,
          acquisitionDate: DateTime(2026, 1, 1),
        ),
      );

      expect(result.isFailure, isTrue);
    });

    test('rejects a negative value', () async {
      final repo = FakeAssetRepository();
      final useCase = CreateAssetUseCase(assetRepository: repo, idGenerator: _FixedId());

      final result = await useCase.execute(
        CreateAssetInput(
          workspaceId: _ws,
          name: 'Laptop',
          category: 'Electronics',
          value: -1,
          acquisitionDate: DateTime(2026, 1, 1),
        ),
      );

      expect(result.isFailure, isTrue);
    });
  });
}
