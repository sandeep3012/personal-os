import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// One filter chip's state, for [FilterBar].
final class FilterOption {
  const FilterOption({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
}

/// The single filter-row shape used by every filterable list (VPS §2,
/// design principle #6) — a horizontal scrollable row of chips + an
/// optional overflow "More filters" chip.
final class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.filters,
    this.onMoreFilters,
  });

  final List<FilterOption> filters;
  final VoidCallback? onMoreFilters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (final filter in filters) ...[
            FilterChip(
              label: Text(filter.label),
              selected: filter.selected,
              onSelected: filter.onSelected,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (onMoreFilters != null)
            ActionChip(
              avatar: const Icon(Icons.tune, size: 18),
              label: const Text('More filters'),
              onPressed: onMoreFilters,
            ),
        ],
      ),
    );
  }
}
