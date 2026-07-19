import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Which [AppSemanticColors] tone a [StatusChip]/tile status maps to.
enum StatusTone { neutral, positive, negative, warning }

/// A small text(+icon) chip for priority, state, or category (VPS §2) —
/// consistent shape/color mapping via [AppSemanticColors] rather than each
/// screen picking its own chip colors.
final class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final color = switch (tone) {
      StatusTone.neutral => semanticColors?.neutral ?? theme.colorScheme.primary,
      StatusTone.positive => semanticColors?.positive ?? theme.colorScheme.primary,
      StatusTone.negative => semanticColors?.negative ?? theme.colorScheme.error,
      StatusTone.warning => semanticColors?.warning ?? theme.colorScheme.tertiary,
    };

    return Semantics(
      label: label,
      child: Chip(
        avatar: icon == null ? null : Icon(icon, size: 16, color: color),
        label: Text(label),
        labelStyle: theme.textTheme.labelMedium?.copyWith(color: color),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide.none,
      ),
    );
  }
}
