import 'package:application/application.dart';
import 'package:feature_goals/src/application/use_cases/archive_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/complete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/create_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/delete_goal_use_case.dart';
import 'package:feature_goals/src/application/use_cases/get_goals_use_case.dart';
import 'package:feature_goals/src/application/use_cases/update_goal_use_case.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_id.dart';
import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [GoalsPage]: loads all goals and exposes create/update/complete/
/// archive/delete operations.
///
/// Depends only on use cases — never on [IGoalRepository] directly. All
/// business rules (title validation, status-transition legality, etc.) are
/// enforced by the use cases and the [Goal] entity beneath them; this
/// ViewModel neither duplicates nor bypasses them — it only orchestrates
/// calls and surfaces whatever [Result] they return. Mirrors
/// `AccountsViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) — this
/// ViewModel never invents or hardcodes a workspace identifier, and reloads
/// automatically when [WorkspaceContext] reports a switch.
final class GoalsViewModel extends ChangeNotifier {
  GoalsViewModel({
    required GetGoalsUseCase getGoalsUseCase,
    required CreateGoalUseCase createGoalUseCase,
    required UpdateGoalUseCase updateGoalUseCase,
    required CompleteGoalUseCase completeGoalUseCase,
    required ArchiveGoalUseCase archiveGoalUseCase,
    required DeleteGoalUseCase deleteGoalUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getGoalsUseCase = getGoalsUseCase,
        _createGoalUseCase = createGoalUseCase,
        _updateGoalUseCase = updateGoalUseCase,
        _completeGoalUseCase = completeGoalUseCase,
        _archiveGoalUseCase = archiveGoalUseCase,
        _deleteGoalUseCase = deleteGoalUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetGoalsUseCase _getGoalsUseCase;
  final CreateGoalUseCase _createGoalUseCase;
  final UpdateGoalUseCase _updateGoalUseCase;
  final CompleteGoalUseCase _completeGoalUseCase;
  final ArchiveGoalUseCase _archiveGoalUseCase;
  final DeleteGoalUseCase _deleteGoalUseCase;

  /// Reloads the goal list for the newly-active workspace — presentation
  /// plumbing only, mirrors `AccountsViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Goal>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with goals), or error.
  AsyncState<List<Goal>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads goals for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads goals while keeping the current list visible ([isRefreshing]
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
        await _getGoalsUseCase.execute(GetGoalsInput(workspaceId: workspaceId));

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

  /// Creates a new goal, then reloads the list on success.
  Future<Result<Goal>> createGoal({
    required String name,
    required double targetValue,
    String? unit,
    GoalTargetDate? targetDate,
    String? description,
  }) async {
    final result = await _createGoalUseCase.execute(CreateGoalInput(
      workspaceId: workspaceId,
      name: name,
      targetValue: targetValue,
      unit: unit,
      targetDate: targetDate,
      description: description,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates a goal's name/description/target, then reloads the list on
  /// success. Status is intentionally not settable here — use
  /// [archiveGoal]; progress is intentionally not settable here — use
  /// [completeGoal].
  Future<Result<Goal>> updateGoal({
    required GoalId goalId,
    String? name,
    String? description,
    double? targetValue,
    String? unit,
    GoalTargetDate? targetDate,
  }) async {
    final result = await _updateGoalUseCase.execute(UpdateGoalInput(
      goalId: goalId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      targetValue: targetValue,
      unit: unit,
      targetDate: targetDate,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Records [progressDelta] toward the goal's target, then reloads the
  /// list on success.
  ///
  /// If the update is not legal (e.g. the goal is not active), the
  /// returned [Result.failure] carries that exact message; this ViewModel
  /// does not re-check the rule.
  Future<Result<Goal>> completeGoal(GoalId goalId, double progressDelta) async {
    final result = await _completeGoalUseCase.execute(
      CompleteGoalInput(
        goalId: goalId,
        workspaceId: workspaceId,
        progressDelta: progressDelta,
      ),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives a goal, then reloads the list on success.
  Future<Result<Goal>> archiveGoal(GoalId goalId) async {
    final result = await _archiveGoalUseCase.execute(
      ArchiveGoalInput(goalId: goalId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes a goal, then reloads the list on success.
  Future<Result<void>> deleteGoal(GoalId goalId) async {
    final result = await _deleteGoalUseCase.execute(
      DeleteGoalInput(goalId: goalId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
