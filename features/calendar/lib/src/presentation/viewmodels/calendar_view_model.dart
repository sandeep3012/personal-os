import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/archive_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/create_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/delete_event_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/application/use_cases/update_event_use_case.dart';
import 'package:feature_calendar/src/domain/entities/event.dart';
import 'package:feature_calendar/src/domain/value_objects/event_id.dart';
import 'package:feature_calendar/src/domain/value_objects/event_time_range.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [CalendarPage]: loads all events and exposes create/update/
/// archive/delete operations.
///
/// Depends only on use cases — never on [IEventRepository] directly. All
/// business rules (title validation, time-range ordering,
/// status-transition legality, etc.) are enforced by the use cases and the
/// [Event] entity beneath them; this ViewModel neither duplicates nor
/// bypasses them — it only orchestrates calls and surfaces whatever
/// [Result] they return. Mirrors `NotesViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) —
/// this ViewModel never invents or hardcodes a workspace identifier, and
/// reloads automatically when [WorkspaceContext] reports a switch.
final class CalendarViewModel extends ChangeNotifier {
  CalendarViewModel({
    required GetEventsUseCase getEventsUseCase,
    required CreateEventUseCase createEventUseCase,
    required UpdateEventUseCase updateEventUseCase,
    required ArchiveEventUseCase archiveEventUseCase,
    required DeleteEventUseCase deleteEventUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getEventsUseCase = getEventsUseCase,
        _createEventUseCase = createEventUseCase,
        _updateEventUseCase = updateEventUseCase,
        _archiveEventUseCase = archiveEventUseCase,
        _deleteEventUseCase = deleteEventUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetEventsUseCase _getEventsUseCase;
  final CreateEventUseCase _createEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final ArchiveEventUseCase _archiveEventUseCase;
  final DeleteEventUseCase _deleteEventUseCase;

  /// Reloads the event list for the newly-active workspace — presentation
  /// plumbing only, mirrors `NotesViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Event>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with events), or error.
  AsyncState<List<Event>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads events for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads events while keeping the current list visible ([isRefreshing]
  /// becomes `true` instead of resetting [state] to loading).
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final result =
        await _getEventsUseCase.execute(GetEventsInput(workspaceId: workspaceId));

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    _state = AsyncState.success(result.valueOrNull!);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Creates a new event, then reloads the list on success.
  Future<Result<Event>> createEvent({
    required String title,
    required EventTimeRange timeRange,
    String location = '',
    String description = '',
  }) async {
    final result = await _createEventUseCase.execute(CreateEventInput(
      workspaceId: workspaceId,
      title: title,
      timeRange: timeRange,
      location: location,
      description: description,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates an event's title/time range/location/description, then
  /// reloads the list on success. Status is intentionally not settable
  /// here — use [archiveEvent].
  Future<Result<Event>> updateEvent({
    required EventId eventId,
    String? title,
    EventTimeRange? timeRange,
    String? location,
    String? description,
  }) async {
    final result = await _updateEventUseCase.execute(UpdateEventInput(
      eventId: eventId,
      workspaceId: workspaceId,
      title: title,
      timeRange: timeRange,
      location: location,
      description: description,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives an event, then reloads the list on success.
  Future<Result<Event>> archiveEvent(EventId eventId) async {
    final result = await _archiveEventUseCase.execute(
      ArchiveEventInput(eventId: eventId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes an event, then reloads the list on success.
  Future<Result<void>> deleteEvent(EventId eventId) async {
    final result = await _deleteEventUseCase.execute(
      DeleteEventInput(eventId: eventId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
