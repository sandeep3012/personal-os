import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/archive_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/complete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/create_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/delete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/get_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/application/use_cases/search_goals_use_case.dart';
import 'package:feature_goals/src/application/use_cases/update_goal_use_case.dart';
import 'package:feature_goals/src/data/dao/goal_dao.dart';
import 'package:feature_goals/src/data/database/i_goal_database_executor.dart';
import 'package:feature_goals/src/data/database/i_goal_transaction_runner.dart';
import 'package:feature_goals/src/data/mappers/goal_mapper.dart';
import 'package:feature_goals/src/data/repositories/goal_repository.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/presentation/routes/goals_routes.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_home_view_model.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Goals application layer into the Personal OS DI
/// container (DOC-032). Mirrors `FinanceModule` exactly.
///
/// [IGoalDatabaseExecutor] and [IGoalTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here, the
/// same way `FinanceModule` expects `IFinanceDatabaseExecutor`/
/// `IFinanceTransactionRunner` to already exist in the container by the time
/// a repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before this
/// module resolves.
final class GoalsModule extends FeatureModule {
  const GoalsModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'goals',
        name: 'Goals',
        version: '0.1.0',
        description: 'Personal goal management: create, complete, and '
            'archive goals.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(GoalsRoutes.root);
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
    registrar.registerLazySingleton<GoalMapper>(() => const GoalMapper());

    registrar.registerLazySingleton<GoalDao>(
      () => GoalDao(locator.get<IGoalDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IGoalRepository>(
      () => GoalRepository(
        goalDao: locator.get<GoalDao>(),
        goalMapper: locator.get<GoalMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Finance
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateGoalUseCase>(
      () => CreateGoalUseCase(
        goalRepository: locator.get<IGoalRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateGoalUseCase>(
      () => UpdateGoalUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<CompleteGoalUseCase>(
      () => CompleteGoalUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<ArchiveGoalUseCase>(
      () => ArchiveGoalUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<DeleteGoalUseCase>(
      () => DeleteGoalUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<GetGoalUseCase>(
      () => GetGoalUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<GetGoalsUseCase>(
      () => GetGoalsUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
    registrar.registerFactory<SearchGoalsUseCase>(
      () => SearchGoalsUseCase(goalRepository: locator.get<IGoalRepository>()),
    );
  }

  // ── Presentation ────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Finance
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<GoalsViewModel>(
      () => GoalsViewModel(
        getGoalsUseCase: locator.get<GetGoalsUseCase>(),
        createGoalUseCase: locator.get<CreateGoalUseCase>(),
        updateGoalUseCase: locator.get<UpdateGoalUseCase>(),
        completeGoalUseCase: locator.get<CompleteGoalUseCase>(),
        archiveGoalUseCase: locator.get<ArchiveGoalUseCase>(),
        deleteGoalUseCase: locator.get<DeleteGoalUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<GoalsHomeViewModel>(
      () => GoalsHomeViewModel(
        getGoalsUseCase: locator.get<GetGoalsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
