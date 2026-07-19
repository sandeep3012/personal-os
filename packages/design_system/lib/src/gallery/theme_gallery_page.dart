import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:flutter/material.dart';

/// A development-only showcase of every design-system token and component
/// theme (TIS §1 Milestone 2 deliverable).
///
/// Not wired into any app route — it exists purely to let a developer
/// visually verify [AppThemeBuilder]'s output (typography, colors, spacing,
/// buttons, cards, chips, navigation themes) in light and dark mode before
/// any screen consumes it. No production navigation change is required to
/// use it: mount it directly (e.g. as `home:` in a throwaway `MaterialApp`)
/// during development.
final class ThemeGalleryPage extends StatelessWidget {
  const ThemeGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Gallery')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Section(
            title: 'Typography',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Headline Small', style: theme.textTheme.headlineSmall),
                Text('Title Large', style: theme.textTheme.titleLarge),
                Text('Title Medium', style: theme.textTheme.titleMedium),
                Text('Title Small', style: theme.textTheme.titleSmall),
                Text('Body Large', style: theme.textTheme.bodyLarge),
                Text('Body Medium', style: theme.textTheme.bodyMedium),
                Text('Label Large', style: theme.textTheme.labelLarge),
                Text('Label Small', style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const _Section(
            title: 'Spacing',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _SpacingSwatch(label: 'xs', size: AppSpacing.xs),
                _SpacingSwatch(label: 'sm', size: AppSpacing.sm),
                _SpacingSwatch(label: 'md', size: AppSpacing.md),
                _SpacingSwatch(label: 'lg', size: AppSpacing.lg),
                _SpacingSwatch(label: 'xl', size: AppSpacing.xl),
                _SpacingSwatch(label: 'xxl', size: AppSpacing.xxl),
              ],
            ),
          ),
          _Section(
            title: 'Color Scheme',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ColorSwatch(label: 'primary', color: theme.colorScheme.primary),
                _ColorSwatch(
                  label: 'secondary',
                  color: theme.colorScheme.secondary,
                ),
                _ColorSwatch(
                  label: 'tertiary',
                  color: theme.colorScheme.tertiary,
                ),
                _ColorSwatch(label: 'error', color: theme.colorScheme.error),
                _ColorSwatch(
                  label: 'surface',
                  color: theme.colorScheme.surface,
                ),
              ],
            ),
          ),
          if (semanticColors != null)
            _Section(
              title: 'Semantic Colors',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ColorSwatch(label: 'positive', color: semanticColors.positive),
                  _ColorSwatch(label: 'negative', color: semanticColors.negative),
                  _ColorSwatch(label: 'warning', color: semanticColors.warning),
                  _ColorSwatch(label: 'neutral', color: semanticColors.neutral),
                  _ColorSwatch(label: 'success', color: semanticColors.success),
                ],
              ),
            ),
          if (semanticColors != null)
            _Section(
              title: 'Module Accents',
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final entry in semanticColors.moduleAccents.entries)
                    _ColorSwatch(label: entry.key, color: entry.value),
                ],
              ),
            ),
          _Section(
            title: 'Buttons',
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Filled')),
                OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          ),
          _Section(
            title: 'Chips',
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                const Chip(label: Text('Chip')),
                FilterChip(
                  label: const Text('Selected'),
                  selected: true,
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Unselected'),
                  selected: false,
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          const _Section(
            title: 'Card',
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('A resting Card at AppElevation.card'),
              ),
            ),
          ),
          const _Section(
            title: 'List Tile',
            child: Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet_outlined),
                title: Text('List tile title'),
                subtitle: Text('List tile subtitle'),
                trailing: Text('Trailing'),
              ),
            ),
          ),
          _Section(
            title: 'Navigation Bar',
            child: NavigationBar(
              selectedIndex: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Finance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
              onDestinationSelected: (_) {},
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _SpacingSwatch extends StatelessWidget {
  const _SpacingSwatch({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('$label ($size)', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppSpacing.xs),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
