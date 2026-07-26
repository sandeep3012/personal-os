import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/error_state_view.dart';
import '../../shared/widgets/loading_skeleton.dart';
import '../../shared/widgets/progress_bar.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_header.dart';

/// A one-page catalog of every DOC-034 component in isolation — the
/// "clickable Figma" reference for design review.
class ComponentGalleryScreen extends StatelessWidget {
  const ComponentGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final scheme = Theme.of(context).colorScheme;

    Widget block(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title),
              const SizedBox(height: AppSpacing.sm),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: child),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Component Gallery')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          block(
            'Card',
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Finance'),
                    Text('₹52,400', style: Theme.of(context).textTheme.headlineSmall),
                    Text('+₹400 Today', style: TextStyle(color: semantic.positive)),
                  ],
                ),
              ),
            ),
          ),
          block(
            'Chips',
            Wrap(
              spacing: AppSpacing.sm,
              children: const [
                Chip(label: Text('All')),
                Chip(label: Text('Income')),
                Chip(label: Text('Expense')),
              ],
            ),
          ),
          block(
            'Progress — Linear',
            Column(
              children: [
                AppProgressBar(value: 0.75, color: semantic.moduleAccent('habits')),
                const SizedBox(height: AppSpacing.xs),
                const Align(alignment: Alignment.centerLeft, child: Text('75%')),
              ],
            ),
          ),
          block(
            'Progress — Ring',
            AppProgressRing(value: 0.62, color: semantic.moduleAccent('goals'), label: '62%'),
          ),
          block('Empty State', const EmptyStateView(icon: '📄', title: 'No Notes Yet', message: 'Create your first note', actionLabel: 'New Note')),
          block('Loading — Skeleton', const LoadingSkeletonList(rows: 2)),
          block('Loading — Spinner', const SizedBox(height: 40, child: LoadingSpinner())),
          block('Error State', ErrorStateView(onRetry: () {})),
          block(
            'FAB',
            Align(
              alignment: Alignment.centerLeft,
              child: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
            ),
          ),
          block(
            'Buttons',
            Row(
              children: [
                FilledButton(onPressed: () {}, child: const Text('Primary')),
                const SizedBox(width: AppSpacing.sm),
                OutlinedButton(onPressed: () {}, child: const Text('Secondary')),
              ],
            ),
          ),
          block(
            'Dialog',
            OutlinedButton(
              onPressed: () => showAppConfirmDialog(
                context: context,
                title: 'Delete Transaction?',
                message: "This can't be undone.",
                confirmLabel: 'Delete',
              ),
              child: const Text('Show Confirmation Dialog'),
            ),
          ),
          block(
            'Bottom Sheet',
            OutlinedButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                builder: (context) => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('Sheet content preview'),
                ),
              ),
              child: const Text('Show Bottom Sheet'),
            ),
          ),
          block(
            'Snackbar',
            OutlinedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Transaction deleted'), action: SnackBarAction(label: 'Undo', onPressed: () {})),
              ),
              child: const Text('Show Snackbar'),
            ),
          ),
          block(
            'Module Accent Colors',
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in semantic.moduleAccents.entries)
                  Chip(
                    label: Text(entry.key),
                    avatar: CircleAvatar(backgroundColor: entry.value, radius: 8),
                  ),
              ],
            ),
          ),
          block(
            'Semantic Colors',
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                Chip(label: const Text('Success'), avatar: CircleAvatar(backgroundColor: semantic.success, radius: 8)),
                Chip(label: const Text('Warning'), avatar: CircleAvatar(backgroundColor: semantic.warning, radius: 8)),
                Chip(label: const Text('Error'), avatar: CircleAvatar(backgroundColor: scheme.error, radius: 8)),
                Chip(label: const Text('Neutral'), avatar: CircleAvatar(backgroundColor: semantic.neutral, radius: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
