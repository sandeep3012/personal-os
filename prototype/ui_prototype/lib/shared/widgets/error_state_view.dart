import 'package:flutter/material.dart';

import '../../design/tokens/app_icon_sizes.dart';
import '../../design/tokens/app_spacing.dart';

/// DOC-034 §14 — same skeleton as [EmptyStateView] (icon → title → line →
/// button); only icon/copy/action differ, so the two never look unrelated.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title = "Couldn't load this",
    this.message = 'Check your connection and try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl, horizontal: AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: AppIconSizes.empty, color: scheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
