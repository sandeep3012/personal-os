import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';

/// DOC-034 Part F — Notes. Two-column grid (Notion/Keep-style scanning).
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))]),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: GridView.count(
        padding: const EdgeInsets.all(AppSpacing.md),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.95,
        children: [
          for (final n in FakeData.notes)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title, style: textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        n.preview,
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(n.timeAgo, style: textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
