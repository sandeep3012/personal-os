import 'package:feature_finance/finance.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Finance feature's persistence leaf interfaces
/// ([IFinanceDatabaseExecutor], [IFinanceTransactionRunner]) before
/// [FinanceModule] is registered.
///
/// [FinanceModule] deliberately does not self-register these two types — it
/// documents that it "expects a concrete binding for each to already exist
/// in the container by the time a repository ... is first resolved." No
/// concrete SQL engine has been approved via ADR yet (`IDatabase` in
/// `platform_storage` is contract-only), so this module binds
/// [FileBackedFinanceDatabaseExecutor] — a real, disk-persisted store (data
/// survives an app restart) built by wrapping the already-tested
/// [InMemoryFinanceDatabaseExecutor] SQL-shape engine with a JSON file
/// load/persist layer. Swapping in a real SQL engine later only requires
/// changing this module (and [AppBootstrap]'s file-opening step), not
/// [FinanceModule] or any Finance ViewModel/page.
///
/// Since Milestone 6, [executor]/[runner] are the app's *switchable*
/// wrappers (see `SwitchableFinanceDatabaseExecutor`/
/// `SwitchableFinanceTransactionRunner`), not the raw file-backed pair
/// directly — every Finance repository resolves these same two instances
/// for the app's lifetime, so `DemoModeController` can swap their delegate
/// between real and demo data without any repository being re-created.
///
/// The underlying real executor must already be opened (see
/// [FileBackedFinanceDatabaseExecutor.open]) before this module is added —
/// opening requires resolving a file path (via `path_provider` in
/// production), which is async and therefore cannot happen inside the
/// synchronous [RuntimeModule.register] hook. [AppBootstrap.boot] performs
/// that async open before constructing the [RuntimeBootstrap].
final class FinanceStorageModule extends RuntimeModule {
  const FinanceStorageModule({required this.executor, required this.runner});

  final IFinanceDatabaseExecutor executor;
  final IFinanceTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IFinanceDatabaseExecutor>(executor)
      ..registerSingleton<IFinanceTransactionRunner>(runner);
  }
}
