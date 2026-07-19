import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// The standard title row atop every card group and list section (VPS §2).
///
/// Exactly one of [trailing] or [onSeeAll] should be supplied — [trailing]
/// wins if both are given, letting a caller opt into a fully custom
/// trailing widget when a plain "See all" action isn't enough.
final class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.trailing,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onSeeAll != null)
              TextButton(
                onPressed: onSeeAll,
                child: const Text('See all'),
              ),
          ],
        ),
      ),
    );
  }
}
