import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/archive_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/complete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/create_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/delete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/get_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/application/use_cases/search_habits_use_case.dart';
import 'package:feature_habits/src/application/use_cases/update_habit_use_case.dart';
import 'package:feature_habits/src/data/dao/habit_dao.dart';
import 'package:feature_habits/src/data/database/i_habit_database_executor.dart';
import 'package:feature_habits/src/data/database/i_habit_transaction_runner.dart';
import 'package:feature_habits/src/data/mappers/habit_mapper.dart';
import 'package:feature_habits/src/data/repositories/habit_repository.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/presentation/routes/habits_routes.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_home_view_model.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Habits application layer into the Personal OS DI
/// container (DOC-032). Mirrors `FinanceModule` exactly.
///
/// [IHabitDatabaseExecutor] and [IHabitTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here, the
/// same way `FinanceModule` expects `IFinanceDatabaseExecutor`/
/// `IFinanceTransactionRunner` to already exist in the container by the time
/// a repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before this
/// module resolves.
final class HabitsModule extends FeatureModule {
  const HabitsModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'habits',
        name: 'Habits',
        version: '0.1.0',
        description: 'Personal habit management: create, complete, and '
            'archive habits.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(HabitsRoutes.root);
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
    registrar.registerLazySingleton<HabitMapper>(() => const HabitMapper());

    registrar.registerLazySingleton<HabitDao>(
      () => HabitDao(locator.get<IHabitDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IHabitRepository>(
      () => HabitRepository(
        habitDao: locator.get<HabitDao>(),
        habitMapper: locator.get<HabitMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Finance
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateHabitUseCase>(
      () => CreateHabitUseCase(
        habitRepository: locator.get<IHabitRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateHabitUseCase>(
      () => UpdateHabitUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<CompleteHabitUseCase>(
      () => CompleteHabitUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<ArchiveHabitUseCase>(
      () => ArchiveHabitUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<DeleteHabitUseCase>(
      () => DeleteHabitUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<GetHabitUseCase>(
      () => GetHabitUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<GetHabitsUseCase>(
      () => GetHabitsUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
    registrar.registerFactory<SearchHabitsUseCase>(
      () => SearchHabitsUseCase(habitRepository: locator.get<IHabitRepository>()),
    );
  }

  // ── Presentation ────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Finance
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<HabitsViewModel>(
      () => HabitsViewModel(
        getHabitsUseCase: locator.get<GetHabitsUseCase>(),
        createHabitUseCase: locator.get<CreateHabitUseCase>(),
        updateHabitUseCase: locator.get<UpdateHabitUseCase>(),
        completeHabitUseCase: locator.get<CompleteHabitUseCase>(),
        archiveHabitUseCase: locator.get<ArchiveHabitUseCase>(),
        deleteHabitUseCase: locator.get<DeleteHabitUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<HabitsHomeViewModel>(
      () => HabitsHomeViewModel(
        getHabitsUseCase: locator.get<GetHabitsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
