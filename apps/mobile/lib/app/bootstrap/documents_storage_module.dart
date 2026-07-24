import 'package:feature_documents/documents.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Binds the Documents feature's persistence leaf interfaces
/// ([IDocumentDatabaseExecutor], [IDocumentTransactionRunner]) before
/// [DocumentsModule] is registered. Mirrors `AssetsStorageModule`/
/// `CalendarStorageModule`/`NotesStorageModule` exactly.
///
/// [executor]/[runner] are the app's *switchable* wrappers (see
/// `SwitchableDocumentDatabaseExecutor`/`SwitchableDocumentTransactionRunner`),
/// not the raw file-backed pair directly — every Documents repository
/// resolves these same two instances for the app's lifetime, so
/// `DemoModeController` can swap their delegate between real and demo data
/// without any repository being re-created.
final class DocumentsStorageModule extends RuntimeModule {
  const DocumentsStorageModule({required this.executor, required this.runner});

  final IDocumentDatabaseExecutor executor;
  final IDocumentTransactionRunner runner;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar
      ..registerSingleton<IDocumentDatabaseExecutor>(executor)
      ..registerSingleton<IDocumentTransactionRunner>(runner);
  }
}
