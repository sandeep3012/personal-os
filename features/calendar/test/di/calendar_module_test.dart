import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/archive_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/create_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/delete_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/get_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/search_events_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/update_event_use_case.dart';
import 'package:feature_calendar/src/data/dao/event_dao.dart';
import 'package:feature_calendar/src/data/database/i_event_database_executor.dart';
import 'package:feature_calendar/src/data/database/i_event_transaction_runner.dart';
import 'package:feature_calendar/src/data/database/in_memory_event_database_executor.dart';
import 'package:feature_calendar/src/data/database/in_memory_event_transaction_runner.dart';
import 'package:feature_calendar/src/data/mappers/event_mapper.dart';
import 'package:feature_calendar/src/di/calendar_module.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/presentation/routes/calendar_routes.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_home_view_model.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/utils/id_generator.dart';
import 'package:platform_runtime/registry/service_registry.dart';

/// Verifies that [CalendarModule] composes the persistence layer correctly
/// against a *real* DI container ([ServiceRegistry]) — mirrors Notes'
/// `notes_module_test.dart`. Only the leaf interfaces with no production
/// implementation bound by this module ([IEventDatabaseExecutor],
/// [IEventTransactionRunner]) are supplied here, standing in for whatever
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
    final executor = InMemoryEventDatabaseExecutor();
    registry
      ..registerSingleton<IEventDatabaseExecutor>(executor)
      ..registerSingleton<IEventTransactionRunner>(
        InMemoryEventTransactionRunner(executor),
      );
  });

  group('CalendarModule.register', () {
    test('registers successfully without throwing', () {
      expect(() => const CalendarModule().register(registry), returnsNormally);
    });

    test('registers the feature in FeatureRegistry', () {
      const CalendarModule().register(registry);

      expect(registry.get<FeatureRegistry>().isRegistered('calendar'), isTrue);
    });

    test('registers the calendar route into RouteRegistry', () {
      const CalendarModule().register(registry);

      expect(
        registry.get<RouteRegistry>().containsPath(CalendarRoutes.root.path),
        isTrue,
      );
    });
  });

  group('CalendarModule persistence resolution', () {
    setUp(() => const CalendarModule().register(registry));

    test('resolves EventMapper', () {
      expect(registry.get<EventMapper>(), isA<EventMapper>());
    });

    test('resolves EventDao', () {
      expect(registry.get<EventDao>(), isA<EventDao>());
    });

    test('resolves IEventRepository', () {
      expect(registry.get<IEventRepository>(), isA<IEventRepository>());
    });

    test('resolves IdGenerator', () {
      expect(registry.get<IdGenerator>(), isA<IdGenerator>());
    });
  });

  group('CalendarModule use case resolution', () {
    setUp(() => const CalendarModule().register(registry));

    test('resolves every use case without throwing', () {
      expect(() => registry.get<CreateEventUseCase>(), returnsNormally);
      expect(() => registry.get<UpdateEventUseCase>(), returnsNormally);
      expect(() => registry.get<ArchiveEventUseCase>(), returnsNormally);
      expect(() => registry.get<DeleteEventUseCase>(), returnsNormally);
      expect(() => registry.get<GetEventUseCase>(), returnsNormally);
      expect(() => registry.get<GetEventsUseCase>(), returnsNormally);
      expect(() => registry.get<SearchEventsUseCase>(), returnsNormally);
    });

    test('use cases are factories — resolving twice returns distinct instances',
        () {
      final first = registry.get<CreateEventUseCase>();
      final second = registry.get<CreateEventUseCase>();
      expect(identical(first, second), isFalse);
    });
  });

  group('CalendarModule ViewModel resolution', () {
    setUp(() => const CalendarModule().register(registry));

    test('resolves CalendarViewModel', () {
      expect(registry.get<CalendarViewModel>(), isA<CalendarViewModel>());
    });

    test('resolves CalendarHomeViewModel', () {
      expect(registry.get<CalendarHomeViewModel>(), isA<CalendarHomeViewModel>());
    });

    test('every ViewModel exposes a placeholder loading state', () {
      expect(registry.get<CalendarViewModel>().state.isLoading, isTrue);
      expect(registry.get<CalendarHomeViewModel>().state.isLoading, isTrue);
    });
  });
}
