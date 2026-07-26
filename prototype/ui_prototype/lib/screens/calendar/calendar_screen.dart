import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';

/// DOC-034 Part G — Calendar. Month grid + selected-day agenda.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _selected = 17;
  static const _today = 17;

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('April 2026'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))]),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S']) Text(d, style: textTheme.labelSmall)],
                ),
                const SizedBox(height: AppSpacing.sm),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  children: [
                    for (final day in List.generate(30, (i) => i + 1))
                      GestureDetector(
                        onTap: () => setState(() => _selected = day),
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: day == _selected && day != _today ? scheme.primary : null,
                              border: day == _today
                                  ? Border.all(color: semantic.moduleAccent('calendar'), width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$day',
                              style: TextStyle(color: day == _selected && day != _today ? scheme.onPrimary : null),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text('Thu, $_selected April', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final e in FakeData.todayEvents)
                  Card(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: semantic.moduleAccent('calendar'), width: 3)),
                      ),
                      child: ListTile(
                        title: Text(e.title),
                        leading: Text(e.time, style: textTheme.labelLarge),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
