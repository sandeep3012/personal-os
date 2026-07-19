import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A full-width, bottom-anchored input surface (VPS §2) — the Compact-width
/// counterpart of [AppFormDialog]. Prefer [showAppInputSurface] over
/// constructing this directly so the compact-vs-wide choice is made in one
/// place.
final class AppBottomSheetForm extends StatelessWidget {
  const AppBottomSheetForm({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.onCancel,
    this.saveLabel = 'Save',
    this.cancelLabel = 'Cancel',
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final String saveLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            child,
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  child: Text(cancelLabel),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: onSave,
                  child: Text(saveLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
