import 'package:design_system/src/components/forms/app_bottom_sheet_form.dart';
import 'package:design_system/src/components/forms/app_form_dialog.dart';
import 'package:design_system/src/tokens/app_breakpoints.dart';
import 'package:flutter/material.dart';

/// Shows [child] inside [AppBottomSheetForm] on Compact width or
/// [AppFormDialog] on Medium/Expanded width — the single call site that
/// makes this presentation choice, so no screen decides it independently
/// (TIS §3 "AppInputSurface").
Future<void> showAppInputSurface(
  BuildContext context, {
  required String title,
  required Widget child,
  required VoidCallback onSave,
  VoidCallback? onCancel,
  String saveLabel = 'Save',
  String cancelLabel = 'Cancel',
}) {
  final compact = AppBreakpoints.of(context) == AppWindowSizeClass.compact;

  if (compact) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AppBottomSheetForm(
        title: title,
        onSave: onSave,
        onCancel: onCancel,
        saveLabel: saveLabel,
        cancelLabel: cancelLabel,
        child: child,
      ),
    );
  }

  return showDialog<void>(
    context: context,
    builder: (context) => AppFormDialog(
      title: title,
      onSave: onSave,
      onCancel: onCancel,
      saveLabel: saveLabel,
      cancelLabel: cancelLabel,
      child: child,
    ),
  );
}
