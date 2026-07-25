import 'package:application/application.dart';
import 'package:feature_notes/src/application/use_cases/archive_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/create_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/delete_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/get_note_use_case.dart';
import 'package:feature_notes/src/application/use_cases/get_notes_use_case.dart';
import 'package:feature_notes/src/application/use_cases/search_notes_use_case.dart';
import 'package:feature_notes/src/application/use_cases/update_note_use_case.dart';
import 'package:feature_notes/src/data/dao/note_dao.dart';
import 'package:feature_notes/src/data/database/i_note_database_executor.dart';
import 'package:feature_notes/src/data/database/i_note_transaction_runner.dart';
import 'package:feature_notes/src/data/database/in_memory_note_database_executor.dart';
import 'package:feature_notes/src/data/database/in_memory_note_transaction_runner.dart';
import 'package:feature_notes/src/data/mappers/note_mapper.dart';
import 'package:feature_notes/src/di/notes_module.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/presentation/routes/notes_routes.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_home_view_model.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [NotesModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Goals'
/// `goals_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([INoteDatabaseExecutor],
/// [INoteTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryNoteDatabaseExecutor();
    registry
      ..registerSingleton<INoteDatabaseExecutor>(executor)
      ..registerSingleton<INoteTransactionRunner>(
        InMemoryNoteTransactionRunner(executor),
      );
  });

  group('NotesModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const NotesModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const NotesModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('notes'), isTrue);
    });

    test('registers the notes route into RouteRegistry', () {
      const NotesModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(NotesRoutes.root.path),
        isTrue,
      );
    });
  });

  group('NotesModule persistence resolution', () {
    setUp(() => const NotesModule().register(registry));

    test('resolves NoteMapper', () {
      expect(registry.get<NoteMapper>(), isA<NoteMapper>());
    });

    test('resolves NoteDao', () {
      expect(registry.get<NoteDao>(), isA<NoteDao>());
    });

    test('resolves INoteRepository', () {
      expect(registry.get<INoteRepository>(), isA<INoteRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('NotesModule use case resolution', () {
    setUp(() => const NotesModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateNoteUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateNoteUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveNoteUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteNoteUseCase>(), returnsNormally);
      expect(() => registry.get<GetNoteUseCase>(), returnsNormally);
      expect(() => registry.get<GetNotesUseCase>(), returnsNormally);
      expect(() => registry.get<SearchNotesUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateNoteUseCase>();
      final second = registry.get<CreateNoteUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('NotesModule ViewModel resolution', () {
    setUp(() => const NotesModule().register(registry));

    test('resolves NotesViewModel', () {
      expect(registry.get<NotesViewModel>(), isA<NotesViewModel>());
    });

    test('resolves NotesHomeViewModel', () {
      expect(registry.get<NotesHomeViewModel>(), isA<NotesHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<NotesViewModel>().state.isLoading, isTrue);
      expect(registry.get<NotesHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
