import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';

/// DOC-034 Part M — Section Header: title + optional trailing text-link.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.onTrailingTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (trailing != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(trailing!, style: TextStyle(color: scheme.primary)),
            ),
        ],
      ),
    );
  }
}
