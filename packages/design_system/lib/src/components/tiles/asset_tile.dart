import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:flutter/material.dart';

/// A single tracked-asset row (VPS §5.9.1) — accepts only primitive
/// values, never a feature's `Asset` entity.
final class AssetTile extends StatelessWidget {
  const AssetTile({
    super.key,
    required this.icon,
    required this.name,
    required this.valueText,
    this.deltaLabel,
    this.deltaPositive,
    this.onTap,
  });

  final IconData icon;
  final String name;
  final String valueText;
  final String? deltaLabel;
  final bool? deltaPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final deltaColor = deltaPositive == null
        ? null
        : (deltaPositive! ? semanticColors?.positive : semanticColors?.negative);

    return Semantics(
      label: '$name, $valueText${deltaLabel == null ? '' : ', $deltaLabel'}',
      button: onTap != null,
      excludeSemantics: true,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            icon,
            size: AppIconSizes.standard,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(name),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(valueText, style: theme.textTheme.bodyLarge),
            if (deltaLabel != null)
              Text(
                deltaLabel!,
                style: theme.textTheme.labelSmall?.copyWith(color: deltaColor),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
