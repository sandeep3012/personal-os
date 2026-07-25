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
import 'package:feature_goals/src/data/database/in_memory_goal_database_executor.dart';
import 'package:feature_goals/src/data/database/in_memory_goal_transaction_runner.dart';
import 'package:feature_goals/src/data/mappers/goal_mapper.dart';
import 'package:feature_goals/src/di/goals_module.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/presentation/routes/goals_routes.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_home_view_model.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [GoalsModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Finance's
/// `finance_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([IGoalDatabaseExecutor],
/// [IGoalTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryGoalDatabaseExecutor();
    registry
      ..registerSingleton<IGoalDatabaseExecutor>(executor)
      ..registerSingleton<IGoalTransactionRunner>(
        InMemoryGoalTransactionRunner(executor),
      );
  });

  group('GoalsModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const GoalsModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const GoalsModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('goals'), isTrue);
    });

    test('registers the goals route into RouteRegistry', () {
      const GoalsModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(GoalsRoutes.root.path),
        isTrue,
      );
    });
  });

  group('GoalsModule persistence resolution', () {
    setUp(() => const GoalsModule().register(registry));

    test('resolves GoalMapper', () {
      expect(registry.get<GoalMapper>(), isA<GoalMapper>());
    });

    test('resolves GoalDao', () {
      expect(registry.get<GoalDao>(), isA<GoalDao>());
    });

    test('resolves IGoalRepository', () {
      expect(registry.get<IGoalRepository>(), isA<IGoalRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('GoalsModule use case resolution', () {
    setUp(() => const GoalsModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateGoalUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateGoalUseCase>(), returnsNormally);
      expect(() => registry.get<CompleteGoalUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveGoalUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteGoalUseCase>(), returnsNormally);
      expect(() => registry.get<GetGoalUseCase>(), returnsNormally);
      expect(() => registry.get<GetGoalsUseCase>(), returnsNormally);
      expect(() => registry.get<SearchGoalsUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateGoalUseCase>();
      final second = registry.get<CreateGoalUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('GoalsModule ViewModel resolution', () {
    setUp(() => const GoalsModule().register(registry));

    test('resolves GoalsViewModel', () {
      expect(registry.get<GoalsViewModel>(), isA<GoalsViewModel>());
    });

    test('resolves GoalsHomeViewModel', () {
      expect(registry.get<GoalsHomeViewModel>(), isA<GoalsHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<GoalsViewModel>().state.isLoading, isTrue);
      expect(registry.get<GoalsHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
