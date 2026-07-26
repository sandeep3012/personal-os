import 'package:flutter/material.dart';

/// DOC-034 Part N — the one confirmation-dialog shape shared by every
/// destructive action. Destructive option is never pre-focused.
Future<bool> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  String? message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: message != null ? Text(message) : null,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: TextStyle(color: destructive ? scheme.error : scheme.primary),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
