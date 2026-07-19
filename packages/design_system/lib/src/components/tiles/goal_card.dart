import 'package:design_system/src/components/display/proportion_bar.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A single savings-goal card with a milestone-marked progress bar (VPS
/// §5.6.1) — accepts only primitive values, never a feature's `Goal`
/// entity.
final class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.name,
    required this.progress,
    required this.progressLabel,
    this.milestones = const [0.25, 0.5, 0.75],
    this.onTap,
  });

  final String name;

  /// `[0, 1]`.
  final double progress;

  /// Pre-formatted, e.g. `'₹68,000 / ₹1,00,000'`.
  final String progressLabel;
  final List<double> milestones;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$name, $progressLabel, ${(progress.clamp(0, 1) * 100).round()} percent',
      button: onTap != null,
      excludeSemantics: true,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(progressLabel, style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    ProportionBar(value: progress),
                    for (final milestone in milestones)
                      _MilestoneMarker(fraction: milestone),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneMarker extends StatelessWidget {
  const _MilestoneMarker({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Padding(
        padding: EdgeInsets.only(left: constraints.maxWidth * fraction.clamp(0, 1)),
        child: Container(
          width: 2,
          height: 6,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }
}
