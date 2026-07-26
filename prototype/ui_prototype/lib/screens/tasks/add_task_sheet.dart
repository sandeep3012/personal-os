import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/app_bottom_sheet.dart';

/// DOC-034 Part C §5.3 — Add/Edit Task bottom sheet.
void showAddTaskSheet(BuildContext context, {required void Function(FakeTask) onSave}) {
  showAppBottomSheet(
    context: context,
    title: 'Add Task',
    builder: (context) => _AddTaskForm(onSave: onSave),
  );
}

class _AddTaskForm extends StatefulWidget {
  const _AddTaskForm({required this.onSave});
  final void Function(FakeTask) onSave;

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Title', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextField(controller: _titleController, autofocus: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: AppSpacing.md),
        Text('Due date (optional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () {},
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: const Row(
              children: [Icon(Icons.calendar_today_outlined, size: 18), SizedBox(width: 8), Text('Select date')],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Description (optional)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        const TextField(maxLines: 2),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: _titleController.text.isEmpty
                    ? null
                    : () {
                        widget.onSave(FakeTask(_titleController.text));
                        Navigator.pop(context);
                      },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
