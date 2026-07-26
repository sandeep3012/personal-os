import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/module_icon.dart';
import '../../shared/widgets/progress_bar.dart';
import '../more/more_screen.dart';

/// DOC-034 Part A §3 — Home Dashboard. Greeting → Today hero → module
/// cards → More-modules preview grid.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning, Rohan'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Card(
                color: scheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY',
                        style: textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final e in FakeData.todayEvents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('${e.time}  ${e.title}',
                              style: textTheme.bodyLarge?.copyWith(color: scheme.onPrimaryContainer)),
                        ),
                      Text(
                        '${FakeData.tasksActiveCount} tasks due today',
                        style: textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: Text('View →', style: TextStyle(color: scheme.onPrimaryContainer)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ModuleCard(
              icon: '💰',
              color: semantic.moduleAccent('finance'),
              title: 'Finance',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₹${FakeData.netWorth.toStringAsFixed(0)}', style: textTheme.headlineSmall),
                  Text('+₹250 Today', style: textTheme.bodyMedium?.copyWith(color: semantic.positive)),
                ],
              ),
            ),
            _ModuleCard(
              icon: '✓',
              color: semantic.moduleAccent('tasks'),
              title: 'Tasks',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${FakeData.tasksActiveCount} Active', style: textTheme.bodyLarge),
                  Text('${FakeData.tasksCompletedTodayCount} Due Today', style: textTheme.bodyMedium),
                ],
              ),
            ),
            _ModuleCard(
              icon: '↻',
              color: semantic.moduleAccent('habits'),
              title: 'Habits',
              child: Row(
                children: [
                  Text('${(FakeData.habitsWeekProgress * 100).toInt()}%', style: textTheme.titleLarge),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppProgressBar(
                      value: FakeData.habitsWeekProgress,
                      color: semantic.moduleAccent('habits'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text('More modules', style: textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
                children: [
                  _MiniModule('🚩', 'Goals', semantic.moduleAccent('goals')),
                  _MiniModule('📝', 'Notes', semantic.moduleAccent('notes')),
                  _MiniModule('📦', 'Assets', semantic.moduleAccent('assets')),
                  _MiniModule('📁', 'Docs', semantic.moduleAccent('documents')),
                ].map((w) => GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MoreScreen()),
                      ),
                      child: w,
                    )).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.icon, required this.color, required this.title, required this.child});
  final String icon;
  final Color color;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ModuleIcon(icon: icon, color: color, size: 28),
                  const SizedBox(width: AppSpacing.sm),
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniModule extends StatelessWidget {
  const _MiniModule(this.icon, this.label, this.color);
  final String icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
