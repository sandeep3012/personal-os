import 'package:design_system/design_system.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_view_model.dart';
import 'package:flutter/material.dart';

/// The task list screen.
///
/// Supports viewing tasks, creating, editing, completing (checkbox),
/// archiving (an action inside the edit dialog), and soft-deleting (swipe →
/// dismiss), entirely through [TasksViewModel]. Contains no business logic:
/// every action delegates to a use case and only displays whatever [Result]
/// comes back — mirrors `AccountsPage`/`TransactionsPage`.
///
/// [TaskTile] has no long-press slot (unlike `AccountTile`), so delete is
/// reached via its swipe-to-dismiss gesture instead (matching
/// `TransactionTile`'s convention), and archive — the one extra destructive-
/// ish action Tasks needs beyond what `TaskTile` exposes — lives as a plain
/// button inside the edit dialog's own content area rather than requiring a
/// new design_system widget or gesture slot.
///
/// Built entirely from `package:design_system` components: [AppStateSwitcher]
/// for Loading/Empty/Error, [TaskTile] for each row, [showAppInputSurface]
/// for create/edit.
///
/// Archived tasks are excluded from this list (a presentation-layer display
/// filter, not a business rule — [TasksViewModel.state] still holds them;
/// mirrors `GetAccountsUseCase` excluding inactive accounts, just applied
/// here instead of in the use case, since DOC-032 §12 deliberately keeps
/// `GetTasksUseCase` status-agnostic and leaves filtering to the caller).
final class TasksPage extends StatefulWidget {
  const TasksPage({super.key, required this.viewModel});

  final TasksViewModel viewModel;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Tasks')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Task>>(
            state: widget.viewModel.state,
            isEmpty: (tasks) => _visible(tasks).isEmpty,
            emptyIcon: Icons.check_circle_outline,
            emptyTitle: 'No tasks yet',
            emptyMessage: 'Add a task to get started',
            emptyActionLabel: 'Add Task',
            onEmptyAction: () => _openTaskForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, tasks) {
              final items = _visible(tasks);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final task = items[index];
                  return TaskTile(
                    title: task.title,
                    completed: task.status == TaskStatus.completed,
                    onToggle: (value) => _handleToggle(context, task, value),
                    subtitle: task.description ??
                        (task.dueDate == null ? null : 'Due ${task.dueDate}'),
                    onTap: () => _openTaskForm(context, existing: task),
                    dismissKey: ValueKey(task.id.value),
                    onDismissed: () => _deleteTask(context, task),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openTaskForm(context),
          tooltip: 'Add task',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Task> _visible(List<Task> tasks) =>
      tasks.where((t) => t.status != TaskStatus.archived).toList();

  /// Only forward-completes on check — unchecking a completed task would
  /// mean "reopen," which the approved transition table does not support
  /// (DOC-032 §11), so that direction is a no-op rather than an error the
  /// user would need to dismiss.
  void _handleToggle(BuildContext context, Task task, bool? value) {
    if (value == true && task.status != TaskStatus.completed) {
      _completeTask(context, task);
    }
  }

  Future<void> _completeTask(BuildContext context, Task task) async {
    final result = await widget.viewModel.completeTask(task.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _archiveTask(BuildContext context, Task task) async {
    final result = await widget.viewModel.archiveTask(task.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final result = await widget.viewModel.deleteTask(task.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _openTaskForm(BuildContext context, {Task? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Task' : 'Edit Task',
      onSave: () => _saveTaskForm(
        context,
        existing: existing,
        titleController: titleController,
        descriptionController: descriptionController,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormField(label: 'Title', controller: titleController, autofocus: true),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(
            label: 'Description (optional)',
            controller: descriptionController,
          ),
          if (existing != null &&
              existing.status != TaskStatus.archived) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _archiveTask(context, existing);
                },
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveTaskForm(
    BuildContext context, {
    required Task? existing,
    required TextEditingController titleController,
    required TextEditingController descriptionController,
  }) async {
    Navigator.of(context).pop();

    final description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    final result = existing == null
        ? await widget.viewModel.createTask(
            title: titleController.text,
            description: description,
          )
        : await widget.viewModel.updateTask(
            taskId: existing.id,
            title: titleController.text,
            description: description,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
