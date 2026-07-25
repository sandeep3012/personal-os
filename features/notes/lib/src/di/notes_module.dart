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
import 'package:feature_notes/src/data/mappers/note_mapper.dart';
import 'package:feature_notes/src/data/repositories/note_repository.dart';
import 'package:feature_notes/src/domain/repositories/i_note_repository.dart';
import 'package:feature_notes/src/presentation/routes/notes_routes.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_home_view_model.dart';
import 'package:feature_notes/src/presentation/viewmodels/notes_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Notes application layer into the Personal OS DI
/// container. Mirrors `GoalsModule` exactly.
///
/// [INoteDatabaseExecutor] and [INoteTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here, the
/// same way `GoalsModule` expects `IGoalDatabaseExecutor`/
/// `IGoalTransactionRunner` to already exist in the container by the time a
/// repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before this
/// module resolves.
final class NotesModule extends FeatureModule {
  const NotesModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'notes',
        name: 'Notes',
        version: '0.1.0',
        description: 'Free-form note taking: create, tag, and archive notes.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(NotesRoutes.root);
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

  // ── Persistence ────────────────────────────────────────────────────────────

  void _registerPersistence(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerLazySingleton<NoteMapper>(() => const NoteMapper());

    registrar.registerLazySingleton<NoteDao>(
      () => NoteDao(locator.get<INoteDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<INoteRepository>(
      () => NoteRepository(
        noteDao: locator.get<NoteDao>(),
        noteMapper: locator.get<NoteMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Goals
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateNoteUseCase>(
      () => CreateNoteUseCase(
        noteRepository: locator.get<INoteRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateNoteUseCase>(
      () => UpdateNoteUseCase(noteRepository: locator.get<INoteRepository>()),
    );
    registrar.registerFactory<ArchiveNoteUseCase>(
      () => ArchiveNoteUseCase(noteRepository: locator.get<INoteRepository>()),
    );
    registrar.registerFactory<DeleteNoteUseCase>(
      () => DeleteNoteUseCase(noteRepository: locator.get<INoteRepository>()),
    );
    registrar.registerFactory<GetNoteUseCase>(
      () => GetNoteUseCase(noteRepository: locator.get<INoteRepository>()),
    );
    registrar.registerFactory<GetNotesUseCase>(
      () => GetNotesUseCase(noteRepository: locator.get<INoteRepository>()),
    );
    registrar.registerFactory<SearchNotesUseCase>(
      () => SearchNotesUseCase(noteRepository: locator.get<INoteRepository>()),
    );
  }

  // ── Presentation ────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Goals
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<NotesViewModel>(
      () => NotesViewModel(
        getNotesUseCase: locator.get<GetNotesUseCase>(),
        createNoteUseCase: locator.get<CreateNoteUseCase>(),
        updateNoteUseCase: locator.get<UpdateNoteUseCase>(),
        archiveNoteUseCase: locator.get<ArchiveNoteUseCase>(),
        deleteNoteUseCase: locator.get<DeleteNoteUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<NotesHomeViewModel>(
      () => NotesHomeViewModel(
        getNotesUseCase: locator.get<GetNotesUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
