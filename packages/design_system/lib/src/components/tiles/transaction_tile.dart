import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Which visual treatment a [TransactionTile] gets — accepted as a plain
/// enum, never a feature's `TransactionType`.
enum TransactionTileType { expense, income, transfer }

/// A single transaction row (VPS §2/§5.3.4) — accepts only primitive
/// values. When [onDismissed] is supplied, [dismissKey] must be a stable,
/// unique key for the underlying [Dismissible] (e.g. the transaction id).
final class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amountText,
    this.onTap,
    this.onDismissed,
    this.dismissKey,
  }) : assert(
          onDismissed == null || dismissKey != null,
          'dismissKey is required when onDismissed is supplied',
        );

  final TransactionTileType type;
  final String title;
  final String subtitle;
  final String amountText;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final Key? dismissKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();

    final (icon, color) = switch (type) {
      TransactionTileType.expense => (
          Icons.arrow_downward,
          semanticColors?.negative ?? theme.colorScheme.error,
        ),
      TransactionTileType.income => (
          Icons.arrow_upward,
          semanticColors?.positive ?? theme.colorScheme.primary,
        ),
      TransactionTileType.transfer => (
          Icons.swap_horiz,
          semanticColors?.neutral ?? theme.colorScheme.tertiary,
        ),
    };

    final tile = Semantics(
      label: '$title, $subtitle, $amountText',
      button: onTap != null,
      excludeSemantics: true,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(amountText, style: theme.textTheme.bodyLarge?.copyWith(color: color)),
        onTap: onTap,
      ),
    );

    if (onDismissed == null) return tile;

    return Dismissible(
      key: dismissKey!,
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed!(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      child: tile,
    );
  }
}
