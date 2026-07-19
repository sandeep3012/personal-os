import 'package:design_system/src/tokens/app_motion.dart';
import 'package:design_system/src/tokens/app_radius.dart';
import 'package:flutter/material.dart';

/// A thin horizontal bar showing relative proportion (VPS §2) — Category
/// spend, Asset allocation.
///
/// [value] is clamped to `[0, 1]`. Animates its fill width via
/// [TweenAnimationBuilder] whenever [value] changes.
final class ProportionBar extends StatelessWidget {
  const ProportionBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 6,
    this.semanticLabel,
  });

  final double value;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final duration = AppMotion.durationOrZero(context, AppMotion.page);

    return Semantics(
      label: semanticLabel ?? '${(clamped * 100).round()} percent',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.chipStadium),
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              Container(
                height: height,
                width: constraints.maxWidth,
                color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clamped),
                duration: duration,
                curve: AppMotion.standardCurve,
                builder: (context, animatedValue, _) => Container(
                  height: height,
                  width: constraints.maxWidth * animatedValue,
                  color: color ?? theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
