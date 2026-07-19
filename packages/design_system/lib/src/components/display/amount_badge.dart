import 'package:design_system/src/components/display/status_chip.dart';
import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// A small pill showing a count or delta (VPS §2) — overlaid on an
/// icon/avatar (e.g. a streak count, an overdue-items count).
///
/// Renders nothing when [count] is zero or negative — a badge with no
/// meaningful count to show should simply not exist, rather than showing
/// `'0'`.
final class AmountBadge extends StatelessWidget {
  const AmountBadge({
    super.key,
    required this.count,
    this.tone = StatusTone.neutral,
    this.semanticLabel,
  });

  final int count;
  final StatusTone tone;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final color = switch (tone) {
      StatusTone.neutral => semanticColors?.neutral ?? theme.colorScheme.primary,
      StatusTone.positive => semanticColors?.positive ?? theme.colorScheme.primary,
      StatusTone.negative => semanticColors?.negative ?? theme.colorScheme.error,
      StatusTone.warning => semanticColors?.warning ?? theme.colorScheme.tertiary,
    };

    return Semantics(
      label: semanticLabel ?? '$count',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
