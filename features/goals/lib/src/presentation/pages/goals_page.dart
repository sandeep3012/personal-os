import 'package:design_system/design_system.dart';
import 'package:feature_goals/src/domain/entities/goal.dart';
import 'package:feature_goals/src/domain/value_objects/goal_status.dart';
import 'package:feature_goals/src/presentation/viewmodels/goals_view_model.dart';
import 'package:flutter/material.dart';

/// The goal list screen.
///
/// Supports viewing goals, creating, editing, marking complete (checkbox),
/// archiving (an action inside the edit dialog), and soft-deleting (swipe →
/// dismiss), entirely through [GoalsViewModel]. Contains no business logic:
/// every action delegates to a use case and only displays whatever [Result]
/// comes back — mirrors `TasksPage`/`HabitsPage`.
///
/// Built entirely from `package:design_system` components: [AppStateSwitcher]
/// for Loading/Empty/Error, [TaskTile] (the design system's generic
/// checkbox-row tile — reused as-is, not forked into a Goals-specific
/// widget, per the Design System being frozen) for each row, and
/// [showAppInputSurface] for create/edit. Progress toward the target is
/// surfaced via [TaskTile.subtitle].
///
/// Archived goals are excluded from this list (a presentation-layer display
/// filter, not a business rule — [GoalsViewModel.state] still holds them;
/// mirrors [TasksPage] excluding archived tasks the same way).
final class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key, required this.viewModel});

  final GoalsViewModel viewModel;

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
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
        appBar: AppBar(title: const Text('Goals')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Goal>>(
            state: widget.viewModel.state,
            isEmpty: (goals) => _visible(goals).isEmpty,
            emptyIcon: Icons.flag_outlined,
            emptyTitle: 'No goals yet',
            emptyMessage: 'Add a goal to start tracking progress',
            emptyActionLabel: 'Add Goal',
            onEmptyAction: () => _openGoalForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, goals) {
              final items = _visible(goals);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final goal = items[index];
                  return TaskTile(
                    title: goal.name,
                    completed: goal.status == GoalStatus.completed,
                    onToggle: (value) => _handleToggle(context, goal, value),
                    subtitle: _subtitle(goal),
                    onTap: () => _openGoalForm(context, existing: goal),
                    dismissKey: ValueKey(goal.id.value),
                    onDismissed: () => _deleteGoal(context, goal),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openGoalForm(context),
          tooltip: 'Add goal',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Goal> _visible(List<Goal> goals) =>
      goals.where((g) => g.status != GoalStatus.archived).toList();

  String _subtitle(Goal goal) {
    final unit = goal.unit == null ? '' : ' ${goal.unit}';
    final progress =
        'Progress: ${goal.currentProgress.toStringAsFixed(0)}$unit / '
        '${goal.targetValue.toStringAsFixed(0)}$unit';
    return goal.description == null
        ? progress
        : '${goal.description} · $progress';
  }

  /// Checking marks the goal fully complete (records the remaining progress
  /// then transitions to [GoalStatus.completed]); unchecking is a no-op —
  /// mirrors Habits' "no undo" completion semantics.
  void _handleToggle(BuildContext context, Goal goal, bool? value) {
    if (value == true && goal.status == GoalStatus.active) {
      _completeGoal(context, goal);
    }
  }

  Future<void> _completeGoal(BuildContext context, Goal goal) async {
    final remaining = goal.targetValue - goal.currentProgress;
    final result = await widget.viewModel.completeGoal(
      goal.id,
      remaining > 0 ? remaining : 0,
    );
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _archiveGoal(BuildContext context, Goal goal) async {
    final result = await widget.viewModel.archiveGoal(goal.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _deleteGoal(BuildContext context, Goal goal) async {
    final result = await widget.viewModel.deleteGoal(goal.id);
    if (!context.mounted) return;
    if (result.isFailure) {
      _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _openGoalForm(BuildContext context, {Goal? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    final targetController = TextEditingController(
      text: existing == null ? '' : existing.targetValue.toStringAsFixed(0),
    );
    final unitController = TextEditingController(text: existing?.unit ?? '');

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Goal' : 'Edit Goal',
      onSave: () => _saveGoalForm(
        context,
        existing: existing,
        nameController: nameController,
        descriptionController: descriptionController,
        targetController: targetController,
        unitController: unitController,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormField(label: 'Name', controller: nameController, autofocus: true),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(
            label: 'Description (optional)',
            controller: descriptionController,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(
            label: 'Target value',
            controller: targetController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(label: 'Unit (optional)', controller: unitController),
          if (existing != null && existing.status == GoalStatus.active) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _archiveGoal(context, existing);
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

  Future<void> _saveGoalForm(
    BuildContext context, {
    required Goal? existing,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required TextEditingController targetController,
    required TextEditingController unitController,
  }) async {
    Navigator.of(context).pop();

    final description =
        descriptionController.text.isEmpty ? null : descriptionController.text;
    final unit = unitController.text.isEmpty ? null : unitController.text;
    final targetValue = double.tryParse(targetController.text) ?? 0;

    final result = existing == null
        ? await widget.viewModel.createGoal(
            name: nameController.text,
            targetValue: targetValue,
            unit: unit,
            description: description,
          )
        : await widget.viewModel.updateGoal(
            goalId: existing.id,
            name: nameController.text,
            description: description,
            targetValue: targetValue,
            unit: unit,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
