import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A single calendar-event row (VPS §5.7.1) — accepts only primitive
/// values, never a feature's `Event`/`Bill` entity.
final class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.dateLabel,
    required this.title,
    this.categoryColor,
    this.amountText,
    this.onTap,
  });

  /// Pre-formatted relative date, e.g. `'Tomorrow'`, `'In 4 days'`.
  final String dateLabel;
  final String title;
  final Color? categoryColor;
  final String? amountText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$dateLabel, $title${amountText == null ? '' : ', $amountText'}',
      button: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                color: categoryColor ?? theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(title, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              if (amountText != null) Text(amountText!, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }
}
