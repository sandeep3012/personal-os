import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A centered, fixed-width input surface (VPS §2) — the Medium/Expanded
/// counterpart of [AppBottomSheetForm]. Prefer [showAppInputSurface] over
/// constructing this directly so the compact-vs-wide choice is made in one
/// place.
final class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
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
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: child,
        ),
      ),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: onSave,
          child: Text(saveLabel),
        ),
      ],
    );
  }
}
