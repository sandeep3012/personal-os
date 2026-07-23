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
import 'package:feature_tasks/src/data/database/in_memory_task_database_executor.dart';
import 'package:feature_tasks/src/data/database/in_memory_task_transaction_runner.dart';
import 'package:feature_tasks/src/data/mappers/task_mapper.dart';
import 'package:feature_tasks/src/di/tasks_module.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/presentation/routes/tasks_routes.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_home_view_model.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [TasksModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Finance's
/// `finance_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([ITaskDatabaseExecutor],
/// [ITaskTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryTaskDatabaseExecutor();
    registry
      ..registerSingleton<ITaskDatabaseExecutor>(executor)
      ..registerSingleton<ITaskTransactionRunner>(
        InMemoryTaskTransactionRunner(executor),
      );
  });

  group('TasksModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const TasksModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const TasksModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('tasks'), isTrue);
    });

    test('registers the tasks route into RouteRegistry', () {
      const TasksModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(TasksRoutes.root.path),
        isTrue,
      );
    });
  });

  group('TasksModule persistence resolution', () {
    setUp(() => const TasksModule().register(registry));

    test('resolves TaskMapper', () {
      expect(registry.get<TaskMapper>(), isA<TaskMapper>());
    });

    test('resolves TaskDao', () {
      expect(registry.get<TaskDao>(), isA<TaskDao>());
    });

    test('resolves ITaskRepository', () {
      expect(registry.get<ITaskRepository>(), isA<ITaskRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('TasksModule use case resolution', () {
    setUp(() => const TasksModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateTaskUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateTaskUseCase>(), returnsNormally);
      expect(() => registry.get<CompleteTaskUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveTaskUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteTaskUseCase>(), returnsNormally);
      expect(() => registry.get<GetTaskUseCase>(), returnsNormally);
      expect(() => registry.get<GetTasksUseCase>(), returnsNormally);
      expect(() => registry.get<SearchTasksUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateTaskUseCase>();
      final second = registry.get<CreateTaskUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('TasksModule ViewModel resolution', () {
    setUp(() => const TasksModule().register(registry));

    test('resolves TasksViewModel', () {
      expect(registry.get<TasksViewModel>(), isA<TasksViewModel>());
    });

    test('resolves TasksHomeViewModel', () {
      expect(registry.get<TasksHomeViewModel>(), isA<TasksHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<TasksViewModel>().state.isLoading, isTrue);
      expect(registry.get<TasksHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
