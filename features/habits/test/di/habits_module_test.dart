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
import 'package:feature_habits/src/data/database/in_memory_habit_database_executor.dart';
import 'package:feature_habits/src/data/database/in_memory_habit_transaction_runner.dart';
import 'package:feature_habits/src/data/mappers/habit_mapper.dart';
import 'package:feature_habits/src/di/habits_module.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/presentation/routes/habits_routes.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_home_view_model.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [HabitsModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Finance's
/// `finance_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([IHabitDatabaseExecutor],
/// [IHabitTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryHabitDatabaseExecutor();
    registry
      ..registerSingleton<IHabitDatabaseExecutor>(executor)
      ..registerSingleton<IHabitTransactionRunner>(
        InMemoryHabitTransactionRunner(executor),
      );
  });

  group('HabitsModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const HabitsModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const HabitsModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('habits'), isTrue);
    });

    test('registers the habits route into RouteRegistry', () {
      const HabitsModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(HabitsRoutes.root.path),
        isTrue,
      );
    });
  });

  group('HabitsModule persistence resolution', () {
    setUp(() => const HabitsModule().register(registry));

    test('resolves HabitMapper', () {
      expect(registry.get<HabitMapper>(), isA<HabitMapper>());
    });

    test('resolves HabitDao', () {
      expect(registry.get<HabitDao>(), isA<HabitDao>());
    });

    test('resolves IHabitRepository', () {
      expect(registry.get<IHabitRepository>(), isA<IHabitRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('HabitsModule use case resolution', () {
    setUp(() => const HabitsModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateHabitUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateHabitUseCase>(), returnsNormally);
      expect(() => registry.get<CompleteHabitUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveHabitUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteHabitUseCase>(), returnsNormally);
      expect(() => registry.get<GetHabitUseCase>(), returnsNormally);
      expect(() => registry.get<GetHabitsUseCase>(), returnsNormally);
      expect(() => registry.get<SearchHabitsUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateHabitUseCase>();
      final second = registry.get<CreateHabitUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('HabitsModule ViewModel resolution', () {
    setUp(() => const HabitsModule().register(registry));

    test('resolves HabitsViewModel', () {
      expect(registry.get<HabitsViewModel>(), isA<HabitsViewModel>());
    });

    test('resolves HabitsHomeViewModel', () {
      expect(registry.get<HabitsHomeViewModel>(), isA<HabitsHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<HabitsViewModel>().state.isLoading, isTrue);
      expect(registry.get<HabitsHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
