import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/progress_bar.dart';

/// DOC-034 Part D — Habits. Week strip + per-habit progress cards.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const doneDays = [true, true, true, false, false, false, false];

    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('This Week', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              return Column(
                children: [
                  Text(days[i], style: textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Icon(
                    doneDays[i] ? Icons.circle : Icons.circle_outlined,
                    size: 18,
                    color: doneDays[i] ? semantic.moduleAccent('habits') : Colors.grey,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final h in FakeData.habits)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(h.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: AppSpacing.sm),
                        Text(h.name, style: textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (h.streak != null)
                      Text('🔥 ${h.streak}-day streak',
                          style: textTheme.bodySmall?.copyWith(color: semantic.warning))
                    else ...[
                      AppProgressBar(
                        value: h.doneCount / h.totalCount,
                        color: h.doneCount > 0 ? semantic.success : Colors.grey,
                      ),
                      const SizedBox(height: 4),
                      Text(h.progressLabel, style: textTheme.bodySmall),
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
