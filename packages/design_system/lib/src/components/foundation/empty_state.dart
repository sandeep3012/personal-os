import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The app-wide "nothing here yet" placeholder (VPS §4).
///
/// Never a bare "No X yet" text — every empty screen uses this component so
/// empty states look and behave identically across every module.
final class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: AppIconSizes.empty,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
