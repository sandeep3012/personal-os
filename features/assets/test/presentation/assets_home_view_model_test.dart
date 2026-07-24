import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

Asset _asset(
  String id, {
  AssetStatus status = AssetStatus.active,
  double value = 100,
}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: AssetId(id),
    workspaceId: _ws,
    name: 'Asset $id',
    category: 'Electronics',
    value: value,
    acquisitionDate: DateTime(2025, 1, 1),
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness() : repo = FakeAssetRepository() {
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);
    viewModel = AssetsHomeViewModel(
      getAssetsUseCase: GetAssetsUseCase(assetRepository: repo),
      workspaceContext: workspaceContext,
    );
  }

  final FakeAssetRepository repo;
  late final WorkspaceContext workspaceContext;
  late final AssetsHomeViewModel viewModel;
}

void main() {
  group('AssetsHomeViewModel.load', () {
    test('starts in a loading state', () {
      final harness = _Harness();
      expect(harness.viewModel.state.isLoading, isTrue);
    });

    test('activeCount counts only active assets', () async {
      final harness = _Harness()
        ..repo.seed([
          _asset('a1', status: AssetStatus.active),
          _asset('a2', status: AssetStatus.active),
          _asset('a3', status: AssetStatus.archived),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.activeCount, 2);
    });

    test('totalValue sums the value of active assets only', () async {
      final harness = _Harness()
        ..repo.seed([
          _asset('a1', status: AssetStatus.active, value: 100),
          _asset('a2', status: AssetStatus.active, value: 250),
          _asset('a3', status: AssetStatus.disposed, value: 999),
        ]);

      await harness.viewModel.load();

      expect(harness.viewModel.state.dataOrNull!.totalValue, 350);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      final harness = _Harness();
      harness.viewModel.dispose();

      expect(() => harness.workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
