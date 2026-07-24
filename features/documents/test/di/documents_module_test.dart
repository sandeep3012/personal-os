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
import 'package:feature_documents/src/data/database/in_memory_document_database_executor.dart';
import 'package:feature_documents/src/data/database/in_memory_document_transaction_runner.dart';
import 'package:feature_documents/src/data/mappers/document_mapper.dart';
import 'package:feature_documents/src/di/documents_module.dart';
import 'package:feature_documents/src/domain/repositories/i_document_repository.dart';
import 'package:feature_documents/src/presentation/routes/documents_routes.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_home_view_model.dart';
import 'package:feature_documents/src/presentation/viewmodels/documents_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [DocumentsModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Notes'
/// `notes_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([IDocumentDatabaseExecutor],
/// [IDocumentTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryDocumentDatabaseExecutor();
    registry
      ..registerSingleton<IDocumentDatabaseExecutor>(executor)
      ..registerSingleton<IDocumentTransactionRunner>(
        InMemoryDocumentTransactionRunner(executor),
      );
  });

  group('DocumentsModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const DocumentsModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const DocumentsModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('documents'), isTrue);
    });

    test('registers the documents route into RouteRegistry', () {
      const DocumentsModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(DocumentsRoutes.root.path),
        isTrue,
      );
    });
  });

  group('DocumentsModule persistence resolution', () {
    setUp(() => const DocumentsModule().register(registry));

    test('resolves DocumentMapper', () {
      expect(registry.get<DocumentMapper>(), isA<DocumentMapper>());
    });

    test('resolves DocumentDao', () {
      expect(registry.get<DocumentDao>(), isA<DocumentDao>());
    });

    test('resolves IDocumentRepository', () {
      expect(registry.get<IDocumentRepository>(), isA<IDocumentRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('DocumentsModule use case resolution', () {
    setUp(() => const DocumentsModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateDocumentUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateDocumentUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveDocumentUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteDocumentUseCase>(), returnsNormally);
      expect(() => registry.get<GetDocumentUseCase>(), returnsNormally);
      expect(() => registry.get<GetDocumentsUseCase>(), returnsNormally);
      expect(() => registry.get<SearchDocumentsUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateDocumentUseCase>();
      final second = registry.get<CreateDocumentUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('DocumentsModule ViewModel resolution', () {
    setUp(() => const DocumentsModule().register(registry));

    test('resolves DocumentsViewModel', () {
      expect(registry.get<DocumentsViewModel>(), isA<DocumentsViewModel>());
    });

    test('resolves DocumentsHomeViewModel', () {
      expect(registry.get<DocumentsHomeViewModel>(), isA<DocumentsHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<DocumentsViewModel>().state.isLoading, isTrue);
      expect(registry.get<DocumentsHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
