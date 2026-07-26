import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'add_task_sheet.dart';
import 'task_details_screen.dart';

/// DOC-034 Part C §5.1 — Tasks list, checkbox-first.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late final List<FakeTask> _tasks = [...FakeData.tasks];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTaskSheet(context, onSave: (t) => setState(() => _tasks.add(t))),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: _filter == 0, onSelected: (_) => setState(() => _filter = 0)),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('Today'), selected: _filter == 1, onSelected: (_) => setState(() => _filter = 1)),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('Upcoming'), selected: _filter == 2, onSelected: (_) => setState(() => _filter = 2)),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: EmptyStateView(
                      icon: '✓',
                      title: 'No tasks yet',
                      message: 'Create your first task to get started.',
                      actionLabel: 'Add Task',
                      onAction: () => showAddTaskSheet(context, onSave: (t) => setState(() => _tasks.add(t))),
                    ),
                  )
                : ListView(
                    children: [
                      for (final t in _tasks)
                        Dismissible(
                          key: ValueKey(t.title),
                          background: Container(
                            color: semantic.negative,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: const Icon(Icons.delete_outline, color: Colors.white),
                          ),
                          onDismissed: (_) => setState(() => _tasks.remove(t)),
                          child: Card(
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () => setState(() {
                                  final i = _tasks.indexOf(t);
                                  _tasks[i] = FakeTask(t.title, subtitle: t.subtitle, completed: !t.completed);
                                }),
                                child: Icon(
                                  t.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                                  color: t.completed ? semantic.moduleAccent('tasks') : null,
                                ),
                              ),
                              title: Text(
                                t.title,
                                style: t.completed
                                    ? textTheme.bodyLarge?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      )
                                    : textTheme.bodyLarge,
                              ),
                              subtitle: t.subtitle != null ? Text(t.subtitle!) : null,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: t)),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
