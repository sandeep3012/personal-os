import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/archive_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/complete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/create_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/delete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/update_task_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [TasksPage]: loads all tasks and exposes create/update/complete/
/// archive/delete operations.
///
/// Depends only on use cases — never on [ITaskRepository] directly. All
/// business rules (title validation, status-transition legality, etc.) are
/// enforced by the use cases and the [Task] entity beneath them; this
/// ViewModel neither duplicates nor bypasses them — it only orchestrates
/// calls and surfaces whatever [Result] they return. Mirrors
/// `AccountsViewModel` exactly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) — this
/// ViewModel never invents or hardcodes a workspace identifier, and reloads
/// automatically when [WorkspaceContext] reports a switch.
final class TasksViewModel extends ChangeNotifier {
  TasksViewModel({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    required CompleteTaskUseCase completeTaskUseCase,
    required ArchiveTaskUseCase archiveTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _completeTaskUseCase = completeTaskUseCase,
        _archiveTaskUseCase = archiveTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final CompleteTaskUseCase _completeTaskUseCase;
  final ArchiveTaskUseCase _archiveTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;

  /// Reloads the task list for the newly-active workspace — presentation
  /// plumbing only, mirrors `AccountsViewModel._handleWorkspaceChanged`.
  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Task>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with tasks), or error.
  AsyncState<List<Task>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads tasks for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads tasks while keeping the current list visible ([isRefreshing]
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
        await _getTasksUseCase.execute(GetTasksInput(workspaceId: workspaceId));

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

  /// Creates a new task, then reloads the list on success.
  Future<Result<Task>> createTask({
    required String title,
    String? description,
    TaskDueDate? dueDate,
  }) async {
    final result = await _createTaskUseCase.execute(CreateTaskInput(
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueDate: dueDate,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates a task's title/description/due date, then reloads the list on
  /// success. Status is intentionally not settable here — use [completeTask]/
  /// [archiveTask].
  Future<Result<Task>> updateTask({
    required TaskId taskId,
    String? title,
    String? description,
    TaskDueDate? dueDate,
  }) async {
    final result = await _updateTaskUseCase.execute(UpdateTaskInput(
      taskId: taskId,
      workspaceId: workspaceId,
      title: title,
      description: description,
      dueDate: dueDate,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Marks a task completed, then reloads the list on success.
  ///
  /// If the transition is not legal from the task's current status (DOC-032
  /// §11 — e.g. it is already archived), the returned [Result.failure]
  /// carries that exact message; this ViewModel does not re-check the rule.
  Future<Result<Task>> completeTask(TaskId taskId) async {
    final result = await _completeTaskUseCase.execute(
      CompleteTaskInput(taskId: taskId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Archives a task, then reloads the list on success.
  Future<Result<Task>> archiveTask(TaskId taskId) async {
    final result = await _archiveTaskUseCase.execute(
      ArchiveTaskInput(taskId: taskId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes a task, then reloads the list on success.
  Future<Result<void>> deleteTask(TaskId taskId) async {
    final result = await _deleteTaskUseCase.execute(
      DeleteTaskInput(taskId: taskId, workspaceId: workspaceId),
    );
    if (result.isSuccess) await load();
    return result;
  }
}
