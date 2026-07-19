import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// One action inside a [FloatingActionMenu].
final class FloatingActionMenuAction {
  const FloatingActionMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// A primary FAB plus optional secondary actions (VPS §2 — Transactions'
/// Expense/Income/Transfer, Home's module-specific quick create).
///
/// The primary action is always a standard, single-tap
/// [FloatingActionButton.extended]. Secondary actions (if any) are reachable
/// without a long-press: a small "more" button opens a bottom sheet listing
/// them — accessible to switch/screen-reader users, per TIS §3's
/// requirement that secondary actions never depend solely on a
/// long-press gesture.
///
/// [compact], when `false` (e.g. Expanded window width), renders secondary
/// actions as an inline button row instead of the bottom-sheet affordance —
/// the caller decides this via [AppBreakpoints], keeping this widget
/// layout-agnostic.
final class FloatingActionMenu extends StatelessWidget {
  const FloatingActionMenu({
    super.key,
    required this.primary,
    this.secondaryActions = const [],
    this.compact = true,
  });

  final FloatingActionMenuAction primary;
  final List<FloatingActionMenuAction> secondaryActions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (secondaryActions.isEmpty) {
      return FloatingActionButton.extended(
        onPressed: primary.onTap,
        icon: Icon(primary.icon),
        label: Text(primary.label),
      );
    }

    if (!compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final action in secondaryActions) ...[
            OutlinedButton.icon(
              onPressed: action.onTap,
              icon: Icon(action.icon),
              label: Text(action.label),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          FloatingActionButton.extended(
            onPressed: primary.onTap,
            icon: Icon(primary.icon),
            label: Text(primary.label),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: null,
          tooltip: 'More actions',
          onPressed: () => _showSecondaryActions(context),
          child: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: AppSpacing.sm),
        FloatingActionButton.extended(
          onPressed: primary.onTap,
          icon: Icon(primary.icon),
          label: Text(primary.label),
        ),
      ],
    );
  }

  Future<void> _showSecondaryActions(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final action in secondaryActions)
              ListTile(
                leading: Icon(action.icon),
                title: Text(action.label),
                onTap: () {
                  Navigator.of(context).pop();
                  action.onTap();
                },
              ),
          ],
        ),
      ),
    );
  }
}
