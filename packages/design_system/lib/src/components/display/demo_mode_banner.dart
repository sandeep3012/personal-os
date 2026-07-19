import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The persistent, dismissible banner shown while one or more modules are
/// displaying sample data instead of real data (VPS §4/§5 — Demo Mode is a
/// first-class experience, not a hidden implementation detail).
///
/// Renders nothing when [moduleNames] is empty — every module having
/// transitioned to real data means the banner simply disappears, with no
/// caller-side conditional needed.
final class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({
    super.key,
    required this.moduleNames,
    this.onDismiss,
    this.onAddRealData,
  });

  final List<String> moduleNames;
  final VoidCallback? onDismiss;
  final VoidCallback? onAddRealData;

  @override
  Widget build(BuildContext context) {
    if (moduleNames.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final message = "You're viewing sample data for ${moduleNames.join(', ')}";

    return Semantics(
      liveRegion: true,
      child: Material(
        color: theme.colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(
                Icons.science_outlined,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              if (onAddRealData != null)
                TextButton(
                  onPressed: onAddRealData,
                  child: const Text('Add real data'),
                ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  icon: const Icon(Icons.close),
                  onPressed: onDismiss,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
