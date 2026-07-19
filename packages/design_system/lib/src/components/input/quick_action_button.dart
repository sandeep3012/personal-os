import 'package:flutter/material.dart';

/// A single shortcut action (VPS §5.2 "Quick Actions row") — icon + label,
/// 48dp minimum tap target via the themed [OutlinedButton] style.
final class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
