import 'package:design_system/src/components/display/status_chip.dart';
import 'package:flutter/material.dart';

/// A single task row (VPS §5.4.1) — accepts only primitive values, never a
/// feature's `Task` entity.
final class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.title,
    required this.completed,
    required this.onToggle,
    this.subtitle,
    this.priorityLabel,
    this.priorityTone = StatusTone.neutral,
    this.onTap,
    this.onDismissed,
    this.dismissKey,
  }) : assert(
          onDismissed == null || dismissKey != null,
          'dismissKey is required when onDismissed is supplied',
        );

  final String title;
  final bool completed;
  final ValueChanged<bool?> onToggle;
  final String? subtitle;
  final String? priorityLabel;
  final StatusTone priorityTone;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final Key? dismissKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = ListTile(
      leading: Checkbox(value: completed, onChanged: onToggle),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          decoration: completed ? TextDecoration.lineThrough : null,
          color: completed ? theme.colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: priorityLabel == null
          ? null
          : StatusChip(label: priorityLabel!, tone: priorityTone),
      onTap: onTap,
    );

    if (onDismissed == null) return tile;

    return Dismissible(
      key: dismissKey!,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed!(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      child: tile,
    );
  }
}
