import 'package:flutter/material.dart';

/// The standard destructive-action confirmation dialog (VPS §2, design
/// principle #5 — "all destructive actions require confirmation").
///
/// Prefer [showConfirmationDialog] over constructing this directly — it
/// wires up the dialog's own dismiss/confirm callbacks for you.
final class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    required this.itemDescription,
    this.title = 'Confirm',
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
  });

  final String itemDescription;
  final String title;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text("Delete $itemDescription? This can't be undone."),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

/// Shows a [ConfirmationDialog] and calls [onConfirm] only if the user
/// confirms — the single call site every destructive action in the app
/// should use, so confirmation copy and behavior never diverge screen to
/// screen.
Future<void> showConfirmationDialog(
  BuildContext context, {
  required String itemDescription,
  required VoidCallback onConfirm,
  String title = 'Confirm',
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      itemDescription: itemDescription,
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
  if (confirmed == true) onConfirm();
}
