import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/archive_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/create_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/delete_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/dispose_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/application/use_cases/update_asset_use_case.dart';
import 'package:feature_assets/src/presentation/pages/assets_page.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_asset_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'asset-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeAssetRepository() {
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
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeAssetRepository repo;
  late final AssetsViewModel viewModel;

  Widget buildPage() => MaterialApp(home: AssetsPage(viewModel: viewModel));

  Future<Result<dynamic>> createDefault({String name = 'Laptop'}) =>
      viewModel.createAsset(
        name: name,
        category: 'Electronics',
        value: 1000,
        acquisitionDate: DateTime(2026, 1, 1),
      );
}

void main() {
  group('AssetsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no assets exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No assets yet'), findsOneWidget);
    });

    testWidgets('shows an asset after loading', (tester) async {
      final harness = _Harness();
      await harness.createDefault(name: 'Standup Desk');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Standup Desk'), findsOneWidget);
    });
  });

  group('AssetsPage — create', () {
    testWidgets('tapping the FAB opens the add-asset dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Asset')),
        findsOneWidget,
      );
    });
  });

  group('AssetsPage — edit', () {
    testWidgets('tapping an asset opens the edit dialog pre-filled with its name',
        (tester) async {
      final harness = _Harness();
      await harness.createDefault(name: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Asset'), findsOneWidget);
    });

    testWidgets('editing the name updates the list', (tester) async {
      final harness = _Harness();
      await harness.createDefault(name: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('AssetsPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the asset',
        (tester) async {
      final harness = _Harness();
      final created = await harness.createDefault(name: 'Asset');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Asset'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived assets are excluded from the visible list.
      expect(find.text('Asset'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('AssetsPage — dispose', () {
    testWidgets('the Dispose button in the edit dialog disposes the asset',
        (tester) async {
      final harness = _Harness();
      final created = await harness.createDefault(name: 'Asset');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Asset'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Dispose'));
      await tester.pumpAndSettle();

      // Disposed assets are excluded from the visible list.
      expect(find.text('Asset'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'disposed');
    });
  });

  group('AssetsPage — delete', () {
    testWidgets('swiping an asset away deletes it', (tester) async {
      final harness = _Harness();
      await harness.createDefault(name: 'Asset');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Asset'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('AssetsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No assets yet'), findsOneWidget);

      await harness.createDefault(name: 'Newly Added');
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
