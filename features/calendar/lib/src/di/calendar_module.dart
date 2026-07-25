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
import 'package:feature_calendar/src/data/mappers/event_mapper.dart';
import 'package:feature_calendar/src/data/repositories/event_repository.dart';
import 'package:feature_calendar/src/domain/repositories/i_event_repository.dart';
import 'package:feature_calendar/src/presentation/routes/calendar_routes.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_home_view_model.dart';
import 'package:feature_calendar/src/presentation/viewmodels/calendar_view_model.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/di/i_service_locator.dart';
import 'package:platform_core/utils/id_generator.dart';

/// Wires the complete Calendar application layer into the Personal OS DI
/// container. Mirrors `NotesModule` exactly.
///
/// [IEventDatabaseExecutor] and [IEventTransactionRunner] are **not**
/// registered by this module — no concrete implementation is bound here,
/// the same way `NotesModule` expects `INoteDatabaseExecutor`/
/// `INoteTransactionRunner` to already exist in the container by the time a
/// repository is first resolved. The app layer (`apps/mobile`) binds a
/// concrete pair (and Demo Mode switchable-executor integration) before
/// this module resolves.
final class CalendarModule extends FeatureModule {
  const CalendarModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
        id: 'calendar',
        name: 'Calendar',
        version: '0.1.0',
        description: 'Scheduled events: create, update, and archive events.',
      );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(CalendarRoutes.root);
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

  // ── Persistence ────────────────────────────────────────────────────────

  void _registerPersistence(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerLazySingleton<EventMapper>(() => const EventMapper());

    registrar.registerLazySingleton<EventDao>(
      () => EventDao(locator.get<IEventDatabaseExecutor>()),
    );

    registrar.registerLazySingleton<IEventRepository>(
      () => EventRepository(
        eventDao: locator.get<EventDao>(),
        eventMapper: locator.get<EventMapper>(),
      ),
    );
  }

  // ── Use cases ──────────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution — matches the Notes
  // convention (use cases are cheap, stateless orchestrators, not shared
  // state).

  void _registerUseCases(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CreateEventUseCase>(
      () => CreateEventUseCase(
        eventRepository: locator.get<IEventRepository>(),
        idGenerator: locator.get<IdGenerator>(),
      ),
    );
    registrar.registerFactory<UpdateEventUseCase>(
      () => UpdateEventUseCase(eventRepository: locator.get<IEventRepository>()),
    );
    registrar.registerFactory<ArchiveEventUseCase>(
      () => ArchiveEventUseCase(eventRepository: locator.get<IEventRepository>()),
    );
    registrar.registerFactory<DeleteEventUseCase>(
      () => DeleteEventUseCase(eventRepository: locator.get<IEventRepository>()),
    );
    registrar.registerFactory<GetEventUseCase>(
      () => GetEventUseCase(eventRepository: locator.get<IEventRepository>()),
    );
    registrar.registerFactory<GetEventsUseCase>(
      () => GetEventsUseCase(eventRepository: locator.get<IEventRepository>()),
    );
    registrar.registerFactory<SearchEventsUseCase>(
      () => SearchEventsUseCase(eventRepository: locator.get<IEventRepository>()),
    );
  }

  // ── Presentation ───────────────────────────────────────────────────────
  //
  // registerFactory: a fresh instance per resolution, matching the Notes
  // convention — ViewModels are recreated per page visit, not shared.

  void _registerViewModels(IDependencyRegistrar registrar, IServiceLocator locator) {
    registrar.registerFactory<CalendarViewModel>(
      () => CalendarViewModel(
        getEventsUseCase: locator.get<GetEventsUseCase>(),
        createEventUseCase: locator.get<CreateEventUseCase>(),
        updateEventUseCase: locator.get<UpdateEventUseCase>(),
        archiveEventUseCase: locator.get<ArchiveEventUseCase>(),
        deleteEventUseCase: locator.get<DeleteEventUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
    registrar.registerFactory<CalendarHomeViewModel>(
      () => CalendarHomeViewModel(
        getEventsUseCase: locator.get<GetEventsUseCase>(),
        workspaceContext: locator.get<WorkspaceContext>(),
      ),
    );
  }
}
