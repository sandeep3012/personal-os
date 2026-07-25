import 'package:application/application.dart';
import 'package:feature_habits/src/application/use_cases/archive_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/complete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/create_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/delete_habit_use_case.dart';
import 'package:feature_habits/src/application/use_cases/get_habits_use_case.dart';
import 'package:feature_habits/src/application/use_cases/update_habit_use_case.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_id.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [HabitsPage]: loads all habits and exposes create/update/complete/
/// archive/delete operations.
///
/// Depends only on use cases — never on [IHabitRepository] directly. All
/// business rules (title validation, status-transition legality, etc.) are
/// enforced by the use cases and the [Habit] entity beneath them; this
/// ViewModel neither duplicates nor bypasses them — it only orchestrates
/// calls and surfaces whatever [Result] they return. Mirrors
/// `AccountsViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) — this
/// ViewModel never invents or hardcodes a workspace identifier, and reloads
/// automatically when [WorkspaceContext] reports a switch.
final class HabitsViewModel extends ChangeNotifier {
  HabitsViewModel({
    required GetHabitsUseCase getHabitsUseCase,
    required CreateHabitUseCase createHabitUseCase,
    required UpdateHabitUseCase updateHabitUseCase,
    required CompleteHabitUseCase completeHabitUseCase,
    required ArchiveHabitUseCase archiveHabitUseCase,
    required DeleteHabitUseCase deleteHabitUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getHabitsUseCase = getHabitsUseCase,
        _createHabitUseCase = createHabitUseCase,
        _updateHabitUseCase = updateHabitUseCase,
        _completeHabitUseCase = completeHabitUseCase,
        _archiveHabitUseCase = archiveHabitUseCase,
        _deleteHabitUseCase = deleteHabitUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetHabitsUseCase _getHabitsUseCase;
  final CreateHabitUseCase _createHabitUseCase;
  final UpdateHabitUseCase _updateHabitUseCase;
  final CompleteHabitUseCase _completeHabitUseCase;
  final ArchiveHabitUseCase _archiveHabitUseCase;
  final DeleteHabitUseCase _deleteHabitUseCase;

  /// Reloads the habit list for the newly-active workspace — presentation
  /// plumbing only, mirrors `AccountsViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Habit>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with habits), or error.
  AsyncState<List<Habit>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads habits for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads habits while keeping the current list visible ([isRefreshing]
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
        await _getHabitsUseCase.execute(GetHabitsInput(workspaceId: workspaceId));

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

  /// Creates a new habit, then reloads the list on success.
  Future<Result<Habit>> createHabit({
    required String name,
    required HabitFrequency frequency,
    String? description,
  }) async {
    final result = await _createHabitUseCase.execute(CreateHabitInput(
      workspaceId: workspaceId,
      name: name,
      frequency: frequency,
      description: description,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates a habit's name/description/frequency, then reloads the list on
  /// success. Status is intentionally not settable here — use
  /// [archiveHabit]; streak/completion state is intentionally not settable
  /// here — use [completeHabit].
  Future<Result<Habit>> updateHabit({
    required HabitId habitId,
    String? name,
    String? description,
    HabitFrequency? frequency,
  }) async {
    final result = await _updateHabitUseCase.execute(UpdateHabitInput(
      habitId: habitId,
      workspaceId: workspaceId,
      name: name,
      description: description,
      frequency: frequency,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Logs a completion for today, advancing the habit's streak, then
  /// reloads the list on success.
  ///
  /// If the completion is not legal (e.g. the habit is archived, or has
  /// already been completed today), the returned [Result.failure] carries
  /// that exact message; this ViewModel does not re-check the rule.
  Future<Result<Habit>> completeHabit(HabitId habitId) async {
    final result = await _completeHabitUseCase.execute(
      CompleteHabitInput(habitId: habitId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives a habit, then reloads the list on success.
  Future<Result<Habit>> archiveHabit(HabitId habitId) async {
    final result = await _archiveHabitUseCase.execute(
      ArchiveHabitInput(habitId: habitId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes a habit, then reloads the list on success.
  Future<Result<void>> deleteHabit(HabitId habitId) async {
    final result = await _deleteHabitUseCase.execute(
      DeleteHabitInput(habitId: habitId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
