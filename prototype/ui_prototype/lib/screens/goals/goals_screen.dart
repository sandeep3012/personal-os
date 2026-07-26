import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/progress_bar.dart';

/// DOC-034 Part E — Goals. One progress bar + percentage per card.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final g in FakeData.goals)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🚩', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(g.title, style: textTheme.titleSmall)),
                        Text('${(g.percent * 100).toInt()}%', style: textTheme.labelLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(g.currentLabel, style: textTheme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    AppProgressBar(
                      value: g.percent,
                      color: g.percent >= 1 ? semantic.success : semantic.moduleAccent('goals'),
                    ),
                    if (g.percent >= 1) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: semantic.success),
                          const SizedBox(width: 4),
                          Text('Achieved', style: textTheme.bodySmall?.copyWith(color: semantic.success)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
