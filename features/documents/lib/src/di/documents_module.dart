import 'package:application/application.dart';
import 'package:feature_documents/src/application/use_cases/archive_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/create_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/delete_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/get_document_use_case.dart';
import 'package:feature_documents/src/application/use_cases/get_documents_use_case.dart';
import 'package:feature_documents/src/application/use_cases/search_documents_use_case.dart';
import 'package:feature_documents/src/application/use_cases/update_document_use_case.dart';
import 'package:feature_documents/src/data/dao/document_dao.dart';
import 'package:feature_documents/src/data/database/i_document_database_executor.dart';
import 'package:feature_documents/src/data/database/i_document_transaction_runner.dart';
import 'package:feature_documents/src/data/mappers/document_mapper.dart';
import 'package:feature_documents/src/data/repositories/document_repository.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/presentation/routes/documents_routes.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_home_view_model.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Documents application layer into the Personal OS DI
/// container. Mirrors `NotesModule` exactly.
///
/// [IDocumentDatabaseExecutor] and [IDocumentTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here,
/// the same way `NotesModule` expects `INoteDatabaseExecutor`/
/// `INoteTransactionRunner` to already exist in the container by the time a
/// repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before
/// this module resolves.
final class DocumentsModule extends FeatureModule {
  const DocumentsModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'documents',
        name: 'Documents',
        version: '0.1.0',
        description: 'Document metadata: create, update, archive, and delete document records.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(DocumentsRoutes.root);
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
    registrar.registerLazySingleton<DocumentMapper>(() => const DocumentMapper());

    registrar.registerLazySingleton<DocumentDao>(
      () => DocumentDao(locator.get<IDocumentDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IDocumentRepository>(
      () => DocumentRepository(
        documentDao: locator.get<DocumentDao>(),
        documentMapper: locator.get<DocumentMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Notes
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateDocumentUseCase>(
      () => CreateDocumentUseCase(
        documentRepository: locator.get<IDocumentRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateDocumentUseCase>(
      () => UpdateDocumentUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
    registrar.registerFactory<ArchiveDocumentUseCase>(
      () => ArchiveDocumentUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
    registrar.registerFactory<DeleteDocumentUseCase>(
      () => DeleteDocumentUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
    registrar.registerFactory<GetDocumentUseCase>(
      () => GetDocumentUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
    registrar.registerFactory<GetDocumentsUseCase>(
      () => GetDocumentsUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
    registrar.registerFactory<SearchDocumentsUseCase>(
      () => SearchDocumentsUseCase(documentRepository: locator.get<IDocumentRepository>()),
    );
  }

  // ── Presentation ───────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Notes
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<DocumentsViewModel>(
      () => DocumentsViewModel(
        getDocumentsUseCase: locator.get<GetDocumentsUseCase>(),
        createDocumentUseCase: locator.get<CreateDocumentUseCase>(),
        updateDocumentUseCase: locator.get<UpdateDocumentUseCase>(),
        archiveDocumentUseCase: locator.get<ArchiveDocumentUseCase>(),
        deleteDocumentUseCase: locator.get<DeleteDocumentUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<DocumentsHomeViewModel>(
      () => DocumentsHomeViewModel(
        getDocumentsUseCase: locator.get<GetDocumentsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
