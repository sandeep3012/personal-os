import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/confirm_dialog.dart';

/// DOC-034 Part C §5.2 — Task Details.
class TaskDetailsScreen extends StatelessWidget {
  const TaskDetailsScreen({super.key, required this.task});

  final FakeTask task;

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final status = task.completed ? 'Complete' : 'In Progress';

    return Scaffold(
      appBar: AppBar(title: const Text('Task'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))]),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Row(
            children: [
              Icon(
                task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.completed ? semantic.moduleAccent('tasks') : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(task.title, style: textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _MetaRow(label: 'Due', value: task.subtitle ?? '—'),
          const SizedBox(height: AppSpacing.md),
          _MetaRow(
            label: 'Status',
            value: status,
            valueColor: task.completed ? semantic.success : semantic.neutral,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Notes', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Include the Finance module metrics section.',
                style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!task.completed)
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Mark Complete')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton(
            onPressed: () async {
              final confirmed = await showAppConfirmDialog(
                context: context,
                title: 'Archive Task?',
                message: 'This task will be moved to your archive.',
                confirmLabel: 'Archive',
              );
              if (confirmed && context.mounted) Navigator.pop(context);
            },
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
        ),
        Text(value, style: textTheme.bodyLarge?.copyWith(color: valueColor)),
      ],
    );
  }
}
