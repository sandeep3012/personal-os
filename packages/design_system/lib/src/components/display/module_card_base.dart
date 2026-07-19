import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shared visual chrome for [SummaryCard] and [ModuleCard] — an icon/accent
/// header, a title, and a body — so the two never drift out of visual sync
/// (TIS §3 "SummaryCard ... shares 90% implementation with ModuleCard via
/// a common private base widget — not a copy-paste duplicate").
final class ModuleCardBase extends StatelessWidget {
  const ModuleCardBase({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.body,
    this.onTap,
    this.trailing,
    this.semanticLabel,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final Widget body;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSizes.avatar,
                height: AppIconSizes.avatar,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: AppIconSizes.standard),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          body,
        ],
      ),
    );

    final card = Card(child: content);

    if (onTap == null) return card;

    return Semantics(
      button: true,
      label: semanticLabel ?? title,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
