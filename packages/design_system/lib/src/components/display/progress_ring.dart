import 'package:design_system/src/tokens/app_motion.dart';
import 'package:flutter/material.dart';

/// A circular progress indicator with a centered label (VPS §2) — Goals
/// progress, Habit weekly completion.
///
/// [progress] is clamped to `[0, 1]`. Animates from its previous value to
/// the new one via [TweenAnimationBuilder] whenever [progress] changes.
final class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 48,
    this.strokeWidth = 6,
    this.label,
    this.color,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final String? label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final duration = AppMotion.durationOrZero(context, AppMotion.page);

    return Semantics(
      label: label ?? '${(clamped * 100).round()} percent',
      excludeSemantics: true,
      child: SizedBox(
        width: size,
        height: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: clamped),
          duration: duration,
          curve: AppMotion.standardCurve,
          builder: (context, animatedValue, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: strokeWidth,
                  color: color ?? theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              if (label != null)
                Text(label!, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
