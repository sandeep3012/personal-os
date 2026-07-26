import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/generic_tile.dart';

/// DOC-034 Part I — Documents. File-type icon + name + size/date.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Documents'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))]),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.upload_file_outlined)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: true, onSelected: (_) {}),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('PDF'), selected: false, onSelected: (_) {}),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('Images'), selected: false, onSelected: (_) {}),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final d in FakeData.documents)
                  GenericTile(
                    icon: d.icon,
                    iconColor: semantic.moduleAccent('documents'),
                    title: d.name,
                    subtitle: '${d.sizeLabel} · ${d.dateLabel}',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
