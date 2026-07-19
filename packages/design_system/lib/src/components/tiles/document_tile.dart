import 'package:design_system/src/components/display/status_chip.dart';
import 'package:flutter/material.dart';

/// A single document row (VPS §5.8.1) — accepts only primitive values,
/// never a feature's `Document` entity.
final class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.icon,
    required this.name,
    required this.categoryLabel,
    this.expiryLabel,
    this.expiryTone = StatusTone.warning,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String categoryLabel;
  final String? expiryLabel;
  final StatusTone expiryTone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name, $categoryLabel${expiryLabel == null ? '' : ', $expiryLabel'}',
      button: onTap != null,
      excludeSemantics: true,
      child: ListTile(
        leading: Icon(icon),
        title: Text(name),
        subtitle: Text(categoryLabel),
        trailing: expiryLabel == null
            ? null
            : StatusChip(label: expiryLabel!, tone: expiryTone),
        onTap: onTap,
      ),
    );
  }
}
