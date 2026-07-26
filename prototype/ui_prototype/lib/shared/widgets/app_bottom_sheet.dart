import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';

/// DOC-034 Part N — generic bottom-sheet shell with drag handle + title,
/// used by every "Add/Edit" flow with ≤5 fields (DOC-033 §11.2).
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context) builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: AppSpacing.lg * 2),
            builder(context),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    ),
  );
}
