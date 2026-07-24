import 'package:feature_assets/assets.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Assets feature's persistence leaf interfaces
/// ([IAssetDatabaseExecutor], [IAssetTransactionRunner]) before
/// [AssetsModule] is registered. Mirrors `CalendarStorageModule`/
/// `NotesStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableAssetDatabaseExecutor`/`SwitchableAssetTransactionRunner`),
/// not the raw file-backed pair directly — every Assets repository
/// resolves these same two instances for the app's lifetime, so
/// `DemoModeController` can swap their delegate between real and demo data
/// without any repository being re-created.
final class AssetsStorageModule extends RuntimeModule {
  const AssetsStorageModule({required this.executor, required this.runner});

  final IAssetDatabaseExecutor executor;
  final IAssetTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IAssetDatabaseExecutor>(executor)
      ..registerSingleton<IAssetTransactionRunner>(runner);
  }
}
