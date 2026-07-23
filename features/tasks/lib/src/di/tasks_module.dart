import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/archive_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/complete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/create_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/delete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/get_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/search_tasks_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/update_task_use_case.dart';
import 'package:feature_tasks/src/data/dao/task_dao.dart';
import 'package:feature_tasks/src/data/database/i_task_database_executor.dart';
import 'package:feature_tasks/src/data/database/i_task_transaction_runner.dart';
import 'package:feature_tasks/src/data/mappers/task_mapper.dart';
import 'package:feature_tasks/src/data/repositories/task_repository.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/presentation/routes/tasks_routes.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_home_view_model.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Tasks application layer into the Personal OS DI
/// container (DOC-032). Mirrors `FinanceModule` exactly.
///
/// [ITaskDatabaseExecutor] and [ITaskTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here, the
/// same way `FinanceModule` expects `IFinanceDatabaseExecutor`/
/// `IFinanceTransactionRunner` to already exist in the container by the time
/// a repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before this
/// module resolves.
final class TasksModule extends FeatureModule {
  const TasksModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'tasks',
        name: 'Tasks',
        version: '0.1.0',
        description: 'Personal task management: create, complete, and '
            'archive tasks.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(TasksRoutes.root);
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
    registrar.registerLazySingleton<TaskMapper>(() => const TaskMapper());

    registrar.registerLazySingleton<TaskDao>(
      () => TaskDao(locator.get<ITaskDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<ITaskRepository>(
      () => TaskRepository(
        taskDao: locator.get<TaskDao>(),
        taskMapper: locator.get<TaskMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Finance
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateTaskUseCase>(
      () => CreateTaskUseCase(
        taskRepository: locator.get<ITaskRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateTaskUseCase>(
      () => UpdateTaskUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<CompleteTaskUseCase>(
      () => CompleteTaskUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<ArchiveTaskUseCase>(
      () => ArchiveTaskUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<DeleteTaskUseCase>(
      () => DeleteTaskUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<GetTaskUseCase>(
      () => GetTaskUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<GetTasksUseCase>(
      () => GetTasksUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
    registrar.registerFactory<SearchTasksUseCase>(
      () => SearchTasksUseCase(taskRepository: locator.get<ITaskRepository>()),
    );
  }

  // ── Presentation ────────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Finance
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<TasksViewModel>(
      () => TasksViewModel(
        getTasksUseCase: locator.get<GetTasksUseCase>(),
        createTaskUseCase: locator.get<CreateTaskUseCase>(),
        updateTaskUseCase: locator.get<UpdateTaskUseCase>(),
        completeTaskUseCase: locator.get<CompleteTaskUseCase>(),
        archiveTaskUseCase: locator.get<ArchiveTaskUseCase>(),
        deleteTaskUseCase: locator.get<DeleteTaskUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<TasksHomeViewModel>(
      () => TasksHomeViewModel(
        getTasksUseCase: locator.get<GetTasksUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
