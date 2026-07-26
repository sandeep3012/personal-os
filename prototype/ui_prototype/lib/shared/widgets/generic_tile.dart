import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import 'module_icon.dart';

/// DOC-034 Part M — the one list-row shape shared by every module tile
/// (accounts, transactions, tasks, habits, assets, documents).
class GenericTile extends StatelessWidget {
  const GenericTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingColor,
    this.leadingWidget,
    this.onTap,
  });

  final String icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Color? trailingColor;
  final Widget? leadingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              leadingWidget ?? ModuleIcon(icon: icon, color: iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: textTheme.bodyLarge),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: textTheme.titleSmall?.copyWith(
                    color: trailingColor ?? scheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
