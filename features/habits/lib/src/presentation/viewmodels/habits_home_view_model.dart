import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Habits summary data — a presentation-layer
/// computation over [GetHabitsUseCase]'s result, not a domain type. Mirrors
/// `FinanceDashboardData`.
final class HabitsDashboardSummary {
  const HabitsDashboardSummary({
    required this.activeCount,
    required this.completedTodayCount,
  });

  /// Count of habits with [HabitStatus.active] — "still being tracked."
  final int activeCount;

  /// Count of habits whose [Habit.lastCompletedAt] falls on today's
  /// calendar date.
  final int completedTodayCount;
}

/// Drives the Habits [ModuleCard] on [HomeDashboardPage] — mirrors
/// `FinanceHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [HabitsViewModel] (the full list page), the same separation
/// Finance keeps between `FinanceHomeViewModel` and `AccountsViewModel`/
/// `TransactionsViewModel`.
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetHabitsUseCase]'s result, mirroring how
/// `FinanceDashboardData` is assembled from several use case results rather
/// than a dedicated summary use case per figure (DOC-032 §15).
final class HabitsHomeViewModel extends ChangeNotifier {
  HabitsHomeViewModel({
    required GetHabitsUseCase getHabitsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getHabitsUseCase = getHabitsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetHabitsUseCase _getHabitsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<HabitsDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<HabitsDashboardSummary> get state => _state;

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

    final result =
        await _getHabitsUseCase.execute(GetHabitsInput(workspaceId: workspaceId));

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final habits = result.valueOrNull!;
    final now = DateTime.now();
    final activeCount =
        habits.where((h) => h.status == HabitStatus.active).length;
    final completedTodayCount = habits.where((h) {
      final lastCompletedAt = h.lastCompletedAt;
      if (lastCompletedAt == null) return false;
      return lastCompletedAt.year == now.year &&
          lastCompletedAt.month == now.month &&
          lastCompletedAt.day == now.day;
    }).length;

    _state = AsyncState.success(HabitsDashboardSummary(
      activeCount: activeCount,
      completedTodayCount: completedTodayCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
