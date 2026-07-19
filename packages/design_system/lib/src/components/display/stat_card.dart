import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:design_system/src/tokens/app_motion.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A single labeled figure with an optional signed delta (VPS §2 —
/// horizontally-scrollable stat rows on Finance Dashboard, Assets Net
/// Worth, Goals overview).
///
/// [value] is a plain `double` so this component never needs a feature's
/// `Money`/domain type — the caller formats it via [valueFormatter].
/// Animates from 0 to [value] once on first appearance (not replayed on
/// every rebuild) via [TweenAnimationBuilder], respecting reduced motion.
final class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueFormatter,
    this.delta,
    this.deltaLabel,
  });

  final IconData icon;
  final String label;
  final double value;

  /// Formats the animated value for display. Defaults to a whole-number
  /// string.
  final String Function(double value)? valueFormatter;

  /// Signed delta (e.g. `2.1` or `-1.4`) — drives the up/down icon and
  /// semantic color. `null` hides the delta row.
  final double? delta;

  /// Pre-formatted delta text (e.g. `'2.1%'`). Defaults to
  /// `'${delta.abs()}%'` when `null` and [delta] is supplied.
  final String? deltaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final formatter = valueFormatter ?? (v) => v.toStringAsFixed(0);
    final duration = AppMotion.durationOrZero(context, AppMotion.standard);

    final deltaPositive = (delta ?? 0) >= 0;
    final deltaColor = delta == null
        ? null
        : (deltaPositive ? semanticColors?.positive : semanticColors?.negative);
    final deltaText = deltaLabel ?? (delta == null ? null : '${delta!.abs()}%');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Semantics(
          label: _semanticLabel(label, value, formatter, deltaPositive, deltaText),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSizes.standard, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.xs),
              Text(label, style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value),
                duration: duration,
                curve: AppMotion.standardCurve,
                builder: (context, animatedValue, _) => Text(
                  formatter(animatedValue),
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (deltaText != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      deltaPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: AppIconSizes.inline,
                      color: deltaColor,
                    ),
                    Text(
                      '${deltaPositive ? '+' : '-'}$deltaText',
                      style: theme.textTheme.labelMedium?.copyWith(color: deltaColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _semanticLabel(
    String label,
    double value,
    String Function(double) formatter,
    bool deltaPositive,
    String? deltaText,
  ) {
    final base = '$label, ${formatter(value)}';
    if (deltaText == null) return base;
    return '$base, ${deltaPositive ? 'up' : 'down'} $deltaText';
  }
}
