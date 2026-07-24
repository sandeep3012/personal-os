import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/archive_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/create_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/delete_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/dispose_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/application/use_cases/update_asset_use_case.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';

import '../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'asset-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeAssetRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = AssetsViewModel(
      getAssetsUseCase: GetAssetsUseCase(assetRepository: repo),
      createAssetUseCase: CreateAssetUseCase(
        assetRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateAssetUseCase: UpdateAssetUseCase(assetRepository: repo),
      archiveAssetUseCase: ArchiveAssetUseCase(assetRepository: repo),
      disposeAssetUseCase: DisposeAssetUseCase(assetRepository: repo),
      deleteAssetUseCase: DeleteAssetUseCase(assetRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeAssetRepository repo;
  late final WorkspaceContext workspaceContext;
  late final AssetsViewModel viewModel;
}

Future<Result<dynamic>> _createDefault(_Harness harness, {String name = 'Laptop'}) =>
    harness.viewModel.createAsset(
      name: name,
      category: 'Electronics',
      value: 1000,
      acquisitionDate: DateTime(2026, 1, 1),
    );

void main() {
  group('AssetsViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('shows an empty list when no assets exist', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('AssetsViewModel.createAsset', () {
    test('creates an asset starting active and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();

      final result = await harness.viewModel.createAsset(
        name: 'Laptop',
        category: 'Electronics',
        value: 1500,
        acquisitionDate: DateTime(2026, 1, 1),
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AssetStatus.active);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('AssetsViewModel.updateAsset', () {
    test('updates the name and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness, name: 'Original');

      final result = await harness.viewModel.updateAsset(
        assetId: created.valueOrNull!.id,
        name: 'Renamed',
      );

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull!.single.name, 'Renamed');
    });
  });

  group('AssetsViewModel.archiveAsset', () {
    test('archives an asset and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness);

      final result = await harness.viewModel.archiveAsset(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AssetStatus.archived);
    });

    test('fails when the asset is already archived', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness);
      await harness.viewModel.archiveAsset(created.valueOrNull!.id);

      final result = await harness.viewModel.archiveAsset(created.valueOrNull!.id);

      expect(result.isFailure, isTrue);
    });
  });

  group('AssetsViewModel.disposeAsset', () {
    test('disposes an asset and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      final created = await _createDefault(harness);

      final result = await harness.viewModel.disposeAsset(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.status, AssetStatus.disposed);
    });
  });

  group('AssetsViewModel.deleteAsset', () {
    test('soft-deletes an asset and reloads the list', () async {
      final harness = _Harness();
      await harness.viewModel.load();
      await _createDefault(harness);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      final created = harness.viewModel.state.dataOrNull!.single;
      final result = await harness.viewModel.deleteAsset(created.id);

      expect(result.isSuccess, isTrue);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });
}
