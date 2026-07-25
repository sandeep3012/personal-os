import 'package:design_system/design_system.dart';
import 'package:feature_habits/src/domain/entities/habit.dart';
import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:feature_habits/src/domain/value_objects/habit_status.dart';
import 'package:feature_habits/src/presentation/viewmodels/habits_view_model.dart';
import 'package:flutter/material.dart';

/// The habit list screen.
///
/// Supports viewing habits, creating, editing, logging a completion
/// (checkbox), archiving (an action inside the edit dialog), and
/// soft-deleting (swipe → dismiss), entirely through [HabitsViewModel].
/// Contains no business logic: every action delegates to a use case and
/// only displays whatever [Result] comes back — mirrors `TasksPage`.
///
/// Built entirely from `package:design_system` components: [AppStateSwitcher]
/// for Loading/Empty/Error, [TaskTile] (the design system's generic
/// checkbox-row tile — reused as-is, not forked into a Habits-specific
/// widget, per the Design System being frozen) for each row, and
/// [showAppInputSurface] for create/edit. The current streak is surfaced via
/// [TaskTile.subtitle] alongside the description.
///
/// Archived habits are excluded from this list (a presentation-layer
/// display filter, not a business rule — [HabitsViewModel.state] still
/// holds them; mirrors [TasksPage] excluding archived tasks the same way).
final class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key, required this.viewModel});

  final HabitsViewModel viewModel;

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
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
        appBar: AppBar(title: const Text('Habits')),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Habit>>(
            state: widget.viewModel.state,
            isEmpty: (habits) => _visible(habits).isEmpty,
            emptyIcon: Icons.local_fire_department_outlined,
            emptyTitle: 'No habits yet',
            emptyMessage: 'Add a habit to start building a streak',
            emptyActionLabel: 'Add Habit',
            onEmptyAction: () => _openHabitForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, habits) {
              final items = _visible(habits);
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final habit = items[index];
                  final completedToday = _completedToday(habit);
                  return TaskTile(
                    title: habit.name,
                    completed: completedToday,
                    onToggle: (value) => _handleToggle(context, habit, value),
                    subtitle: _subtitle(habit),
                    onTap: () => _openHabitForm(context, existing: habit),
                    dismissKey: ValueKey(habit.id.value),
                    onDismissed: () => _deleteHabit(context, habit),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openHabitForm(context),
          tooltip: 'Add habit',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  List<Habit> _visible(List<Habit> habits) =>
      habits.where((h) => h.status != HabitStatus.archived).toList();

  bool _completedToday(Habit habit) {
    final last = habit.lastCompletedAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  String _subtitle(Habit habit) {
    final streak = 'Streak: ${habit.currentStreak} · ${habit.frequency.name}';
    return habit.description == null ? streak : '${habit.description} · $streak';
  }

  /// Only forward-completes on check — a habit already completed today is
  /// shown as checked and unchecking it is a no-op rather than an error the
  /// user would need to dismiss (logging a completion has no "undo" use
  /// case in this pass).
  void _handleToggle(BuildContext context, Habit habit, bool? value) {
    if (value == true && !_completedToday(habit)) {
      _completeHabit(context, habit);
    }
  }

  Future<void> _completeHabit(BuildContext context, Habit habit) async {
    final result = await widget.viewModel.completeHabit(habit.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _archiveHabit(BuildContext context, Habit habit) async {
    final result = await widget.viewModel.archiveHabit(habit.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _deleteHabit(BuildContext context, Habit habit) async {
    final result = await widget.viewModel.deleteHabit(habit.id);
    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _openHabitForm(BuildContext context, {Habit? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final descriptionController =
        TextEditingController(text: existing?.description ?? '');
    var frequency = existing?.frequency ?? HabitFrequency.daily;

    return showAppInputSurface(
      context,
      title: existing == null ? 'Add Habit' : 'Edit Habit',
      onSave: () => _saveHabitForm(
        context,
        existing: existing,
        nameController: nameController,
        descriptionController: descriptionController,
        frequency: frequency,
      ),
      child: StatefulBuilder(
        builder: (context, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(label: 'Name', controller: nameController, autofocus: true),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Description (optional)',
              controller: descriptionController,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<HabitFrequency>(
                segments: const [
                  ButtonSegment(value: HabitFrequency.daily, label: Text('Daily')),
                  ButtonSegment(value: HabitFrequency.weekly, label: Text('Weekly')),
                ],
                selected: {frequency},
                onSelectionChanged: (selection) =>
                    setState(() => frequency = selection.first),
              ),
            ),
            if (existing != null && existing.status != HabitStatus.archived) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _archiveHabit(context, existing);
                  },
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Archive'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveHabitForm(
    BuildContext context, {
    required Habit? existing,
    required TextEditingController nameController,
    required TextEditingController descriptionController,
    required HabitFrequency frequency,
  }) async {
    Navigator.of(context).pop();

    final description =
        descriptionController.text.isEmpty ? null : descriptionController.text;

    final result = existing == null
        ? await widget.viewModel.createHabit(
            name: nameController.text,
            frequency: frequency,
            description: description,
          )
        : await widget.viewModel.updateHabit(
            habitId: existing.id,
            name: nameController.text,
            description: description,
            frequency: frequency,
          );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
