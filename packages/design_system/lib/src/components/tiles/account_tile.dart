import 'package:design_system/src/components/display/status_chip.dart';
import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:flutter/material.dart';

/// A single account row (VPS §2/§5.3.2) — accepts only primitive values,
/// never a feature's `Account` entity, so this component has no dependency
/// on any feature package.
final class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.balanceText,
    this.balanceTone = StatusTone.neutral,
    this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String name;
  final String subtitle;
  final String balanceText;
  final StatusTone balanceTone;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final balanceColor = switch (balanceTone) {
      StatusTone.neutral => null,
      StatusTone.positive => semanticColors?.positive,
      StatusTone.negative => semanticColors?.negative,
      StatusTone.warning => semanticColors?.warning,
    };

    return Semantics(
      label: '$name, $subtitle, $balanceText',
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
        subtitle: Text(subtitle),
        trailing: Text(
          balanceText,
          style: theme.textTheme.bodyLarge?.copyWith(color: balanceColor),
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}
