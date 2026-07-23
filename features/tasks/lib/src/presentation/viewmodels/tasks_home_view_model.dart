import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter/foundation.dart';

/// The Home Dashboard's Tasks summary data — a presentation-layer
/// computation over [GetTasksUseCase]'s result, not a domain type. Mirrors
/// `FinanceDashboardData`.
final class TasksDashboardSummary {
  const TasksDashboardSummary({
    required this.activeCount,
    required this.completedTodayCount,
  });

  /// Count of tasks not yet completed and not archived (`todo` +
  /// `inProgress`) — "still needs doing."
  final int activeCount;

  /// Count of tasks whose [Task.completedAt] falls on today's calendar date.
  final int completedTodayCount;
}

/// Drives the Tasks [ModuleCard] on [HomeDashboardPage] — mirrors
/// `FinanceHomeViewModel` exactly: a small, isolated aggregator ViewModel
/// distinct from [TasksViewModel] (the full list page), the same separation
/// Finance keeps between `FinanceHomeViewModel` and `AccountsViewModel`/
/// `TransactionsViewModel`.
///
/// No new summary use case is introduced — the counts are computed
/// presentation-side from [GetTasksUseCase]'s result, mirroring how
/// `FinanceDashboardData` is assembled from several use case results rather
/// than a dedicated summary use case per figure (DOC-032 §15).
final class TasksHomeViewModel extends ChangeNotifier {
  TasksHomeViewModel({
    required GetTasksUseCase getTasksUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getTasksUseCase = getTasksUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  String get workspaceId => _workspaceContext.workspaceId;

  final GetTasksUseCase _getTasksUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<TasksDashboardSummary> _state = const AsyncState.loading();

  /// The current load state: loading, success (with the summary), or error.
  AsyncState<TasksDashboardSummary> get state => _state;

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
        await _getTasksUseCase.execute(GetTasksInput(workspaceId: workspaceId));

    if (result.isFailure) {
      _state = AsyncState.error(result.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final tasks = result.valueOrNull!;
    final now = DateTime.now();
    final activeCount = tasks
        .where((t) => t.status == TaskStatus.todo || t.status == TaskStatus.inProgress)
        .length;
    final completedTodayCount = tasks.where((t) {
      final completedAt = t.completedAt;
      if (completedAt == null) return false;
      return completedAt.year == now.year &&
          completedAt.month == now.month &&
          completedAt.day == now.day;
    }).length;

    _state = AsyncState.success(TasksDashboardSummary(
      activeCount: activeCount,
      completedTodayCount: completedTodayCount,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
