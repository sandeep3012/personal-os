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
import 'package:feature_assets/src/data/mappers/asset_mapper.dart';
import 'package:feature_assets/src/data/repositories/asset_repository.dart';
import 'package:feature_assets/src/domain/repositories/i_asset_repository.dart';
import 'package:feature_assets/src/presentation/routes/assets_routes.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_home_view_model.dart';
import 'package:feature_assets/src/presentation/viewmodels/assets_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Assets application layer into the Personal OS DI
/// container. Mirrors `NotesModule` exactly.
///
/// [IAssetDatabaseExecutor] and [IAssetTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here,
/// the same way `NotesModule` expects `INoteDatabaseExecutor`/
/// `INoteTransactionRunner` to already exist in the container by the time a
/// repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before
/// this module resolves.
final class AssetsModule extends FeatureModule {
  const AssetsModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'assets',
        name: 'Assets',
        version: '0.1.0',
        description: 'Owned items of value: create, update, dispose, and archive assets.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(AssetsRoutes.root);
  }

  @override
  void registerServices(IDependencyRegistrar registrar) {
    final locator = registrar as IServiceLocator;

    _registerPersistence(registrar, locator);
    _registerUseCases(registrar, locator);
    _registerViewModels(registrar, locator);
  }

  // IdGenerator is registered once by ApplicationModule (cross-feature
  // utility, same rule as WorkspaceContext) — resolved via the locator in
  // _registerUseCases below, never re-registered by this module.

  // ── Persistence ────────────────────────────────────────────────────────

  void _registerPersistence(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerLazySingleton<AssetMapper>(() => const AssetMapper());

    registrar.registerLazySingleton<AssetDao>(
      () => AssetDao(locator.get<IAssetDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IAssetRepository>(
      () => AssetRepository(
        assetDao: locator.get<AssetDao>(),
        assetMapper: locator.get<AssetMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Notes
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateAssetUseCase>(
      () => CreateAssetUseCase(
        assetRepository: locator.get<IAssetRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateAssetUseCase>(
      () => UpdateAssetUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<ArchiveAssetUseCase>(
      () => ArchiveAssetUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<DisposeAssetUseCase>(
      () => DisposeAssetUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<DeleteAssetUseCase>(
      () => DeleteAssetUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<GetAssetUseCase>(
      () => GetAssetUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<GetAssetsUseCase>(
      () => GetAssetsUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
    registrar.registerFactory<SearchAssetsUseCase>(
      () => SearchAssetsUseCase(assetRepository: locator.get<IAssetRepository>()),
    );
  }

  // ── Presentation ───────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Notes
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<AssetsViewModel>(
      () => AssetsViewModel(
        getAssetsUseCase: locator.get<GetAssetsUseCase>(),
        createAssetUseCase: locator.get<CreateAssetUseCase>(),
        updateAssetUseCase: locator.get<UpdateAssetUseCase>(),
        archiveAssetUseCase: locator.get<ArchiveAssetUseCase>(),
        disposeAssetUseCase: locator.get<DisposeAssetUseCase>(),
        deleteAssetUseCase: locator.get<DeleteAssetUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<AssetsHomeViewModel>(
      () => AssetsHomeViewModel(
        getAssetsUseCase: locator.get<GetAssetsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
