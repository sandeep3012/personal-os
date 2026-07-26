import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/generic_tile.dart';

/// DOC-034 Part H — Assets. Mirrors Accounts' "hero total + card list" shape.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;
    final total = FakeData.assets.fold<double>(0, (sum, a) => sum + a.value);

    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Value', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                Text('₹${total.toStringAsFixed(0)}', style: textTheme.headlineMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final a in FakeData.assets)
            GenericTile(
              icon: a.icon,
              iconColor: semantic.moduleAccent('assets'),
              title: a.name,
              trailing: '₹${a.value.toStringAsFixed(0)}',
            ),
        ],
      ),
    );
  }
}
