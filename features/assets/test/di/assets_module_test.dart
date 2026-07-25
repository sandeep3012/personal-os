import 'package:application/application.dart';
import 'package:feature_assets/src/application/use_cases/archive_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/create_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/delete_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/dispose_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/get_asset_use_case.dart';
import 'package:feature_assets/src/application/use_cases/get_assets_use_case.dart';
import 'package:feature_assets/src/application/use_cases/search_assets_use_case.dart';
import 'package:feature_assets/src/application/use_cases/update_asset_use_case.dart';
import 'package:feature_assets/src/data/dao/asset_dao.dart';
import 'package:feature_assets/src/data/database/i_asset_database_executor.dart';
import 'package:feature_assets/src/data/database/i_asset_transaction_runner.dart';
import 'package:feature_assets/src/data/database/in_memory_asset_database_executor.dart';
import 'package:feature_assets/src/data/database/in_memory_asset_transaction_runner.dart';
import 'package:feature_assets/src/data/mappers/asset_mapper.dart';
import 'package:feature_assets/src/di/assets_module.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/presentation/routes/assets_routes.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_home_view_model.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [AssetsModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Notes'
/// `notes_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([IAssetDatabaseExecutor],
/// [IAssetTransactionRunner]) are supplied here, standing in for whatever
/// the app layer's integration pass registers.
void main() {
  late ServiceRegistry registry;

  void seedApplicationLayerPrerequisites() {
    registry
      ..registerSingleton<FeatureRegistry>(FeatureRegistry())
      ..registerSingleton<RouteRegistry>(RouteRegistry())
      ..registerSingleton<StartupPipeline>(StartupPipeline())
      ..registerSingleton<IdGenerator>(const UuidGenerator())
      ..registerSingleton<WorkspaceContext>(
        WorkspaceContext(initialWorkspaceId: WorkspaceContext.defaultWorkspaceId),
      );
  }

  setUp(() {
    registry = ServiceRegistry();
    seedApplicationLayerPrerequisites();
    final executor = InMemoryAssetDatabaseExecutor();
    registry
      ..registerSingleton<IAssetDatabaseExecutor>(executor)
      ..registerSingleton<IAssetTransactionRunner>(
        InMemoryAssetTransactionRunner(executor),
      );
  });

  group('AssetsModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const AssetsModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const AssetsModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('assets'), isTrue);
    });

    test('registers the assets route into RouteRegistry', () {
      const AssetsModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(AssetsRoutes.root.path),
        isTrue,
      );
    });
  });

  group('AssetsModule persistence resolution', () {
    setUp(() => const AssetsModule().register(registry));

    test('resolves AssetMapper', () {
      expect(registry.get<AssetMapper>(), isA<AssetMapper>());
    });

    test('resolves AssetDao', () {
      expect(registry.get<AssetDao>(), isA<AssetDao>());
    });

    test('resolves IAssetRepository', () {
      expect(registry.get<IAssetRepository>(), isA<IAssetRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('AssetsModule use case resolution', () {
    setUp(() => const AssetsModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateAssetUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateAssetUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveAssetUseCase>(), returnsNormally);
      expect(() => registry.get<DisposeAssetUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteAssetUseCase>(), returnsNormally);
      expect(() => registry.get<GetAssetUseCase>(), returnsNormally);
      expect(() => registry.get<GetAssetsUseCase>(), returnsNormally);
      expect(() => registry.get<SearchAssetsUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateAssetUseCase>();
      final second = registry.get<CreateAssetUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('AssetsModule ViewModel resolution', () {
    setUp(() => const AssetsModule().register(registry));

    test('resolves AssetsViewModel', () {
      expect(registry.get<AssetsViewModel>(), isA<AssetsViewModel>());
    });

    test('resolves AssetsHomeViewModel', () {
      expect(registry.get<AssetsHomeViewModel>(), isA<AssetsHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<AssetsViewModel>().state.isLoading, isTrue);
      expect(registry.get<AssetsHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
