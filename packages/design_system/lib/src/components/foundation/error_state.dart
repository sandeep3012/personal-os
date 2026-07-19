import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The app-wide recoverable-failure placeholder (VPS §4).
///
/// [message] must already be a human-readable string — never a raw
/// exception (this component has no knowledge of `AppException`; the
/// caller translates before reaching here). Announced proactively to
/// screen readers via [Semantics.liveRegion] so a failure is noticed
/// without requiring the user to navigate focus onto it.
final class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: AppIconSizes.empty,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Retry'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
