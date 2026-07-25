import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Goals summary data — a presentation-layer
/// computation over [GetGoalsUseCase]'s result, not a domain type. Mirrors
/// `FinanceDashboardData`.
final class GoalsDashboardSummary {
  const GoalsDashboardSummary({
    required this.activeCount,
    required this.completedCount,
  });

  /// Count of goals with [GoalStatus.active] — "still being pursued."
  final int activeCount;

  /// Count of goals with [GoalStatus.completed] — "achieved."
  final int completedCount;
}

/// Drives the Goals [ModuleCard] on [HomeDashboardPage] — mirrors
/// `HabitsHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [GoalsViewModel] (the full list page), the same separation
/// Finance keeps between `FinanceHomeViewModel` and `AccountsViewModel`/
/// `TransactionsViewModel`.
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetGoalsUseCase]'s result, mirroring how
/// `FinanceDashboardData` is assembled from several use case results rather
/// than a dedicated summary use case per figure (DOC-032 §15).
final class GoalsHomeViewModel extends ChangeNotifier {
  GoalsHomeViewModel({
    required GetGoalsUseCase getGoalsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetGoalsUseCase _getGoalsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<GoalsDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<GoalsDashboardSummary> get state => _state;

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

    final result = await _getGoalsUseCase.execute(
      GetGoalsInput(workspaceId: workspaceId),
    );

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final goals = result.valueOrNull!;
    final activeCount = goals.where((g) => g.status == GoalStatus.active).length;
    final completedCount =
        goals.where((g) => g.status == GoalStatus.completed).length;

    _state = AsyncState.success(GoalsDashboardSummary(
      activeCount: activeCount,
      completedCount: completedCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
