import 'package:design_system/src/components/display/proportion_bar.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A single category spend row with an inline [ProportionBar] (VPS
/// §2/§5.3.7) — accepts only primitive values, never a feature's
/// `Category`/`CategoryId`.
final class CategorySummaryTile extends StatelessWidget {
  const CategorySummaryTile({
    super.key,
    required this.name,
    required this.amountText,
    required this.proportion,
    this.color,
    this.onTap,
  });

  final String name;
  final String amountText;

  /// This category's spend relative to the largest category, `[0, 1]`.
  final double proportion;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$name, $amountText',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: theme.textTheme.bodyLarge),
                  Text(amountText, style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ProportionBar(value: proportion, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
