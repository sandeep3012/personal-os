import 'package:design_system/src/components/display/amount_badge.dart';
import 'package:design_system/src/tokens/app_motion.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A single habit row with a streak badge and an animated completion
/// toggle (VPS §5.5.1) — accepts only primitive values, never a feature's
/// `Habit` entity.
final class HabitTile extends StatelessWidget {
  const HabitTile({
    super.key,
    required this.icon,
    required this.name,
    required this.streakCount,
    required this.completedToday,
    required this.onToggle,
  });

  final IconData icon;
  final String name;
  final int streakCount;
  final bool completedToday;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = AppMotion.durationOrZero(context, AppMotion.fast);

    return Semantics(
      label:
          '$name, ${streakCount > 0 ? '$streakCount day streak, ' : ''}'
          '${completedToday ? 'completed today' : 'not completed today'}',
      excludeSemantics: true,
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AmountBadge(count: streakCount, semanticLabel: '$streakCount day streak'),
            const SizedBox(width: AppSpacing.sm),
            AnimatedScale(
              scale: completedToday ? 1.1 : 1.0,
              duration: duration,
              curve: AppMotion.standardCurve,
              child: Checkbox(
                value: completedToday,
                onChanged: (value) => onToggle(value ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
