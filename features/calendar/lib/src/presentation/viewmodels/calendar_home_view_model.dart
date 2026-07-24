import 'package:application/application.dart';
import 'package:feature_calendar/src/application/use_cases/get_events_use_case.dart';
import 'package:feature_calendar/src/domain/value_objects/event_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Calendar summary data — a presentation-layer
/// computation over [GetEventsUseCase]'s result, not a domain type.
/// Mirrors `NotesDashboardSummary`.
final class CalendarDashboardSummary {
  const CalendarDashboardSummary({
    required this.upcomingCount,
    required this.archivedCount,
  });

  /// Count of events with [EventStatus.active] whose start time is in the
  /// future (or now).
  final int upcomingCount;

  /// Count of events with [EventStatus.archived].
  final int archivedCount;
}

/// Drives the Calendar [ModuleCard] on [HomeDashboardPage] — mirrors
/// `NotesHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [CalendarViewModel] (the full list page).
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetEventsUseCase]'s result, mirroring how
/// `NotesDashboardSummary` is assembled.
final class CalendarHomeViewModel extends ChangeNotifier {
  CalendarHomeViewModel({
    required GetEventsUseCase getEventsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getEventsUseCase = getEventsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetEventsUseCase _getEventsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<CalendarDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<CalendarDashboardSummary> get state => _state;

  var _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> load() => _fetch(isRefresh: false);
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final result = await _getEventsUseCase.execute(
      GetEventsInput(workspaceId: workspaceId),
    );

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final events = result.valueOrNull!;
    final now = DateTime.now();
    final upcomingCount = events
        .where((e) =>
            e.status == EventStatus.active && !e.timeRange.start.isBefore(now))
        .length;
    final archivedCount =
        events.where((e) => e.status == EventStatus.archived).length;

    _state = AsyncState.success(CalendarDashboardSummary(
      upcomingCount: upcomingCount,
      archivedCount: archivedCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
