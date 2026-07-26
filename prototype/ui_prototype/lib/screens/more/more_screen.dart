import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../assets/assets_screen.dart';
import '../documents/documents_screen.dart';
import '../gallery/component_gallery_screen.dart';
import '../goals/goals_screen.dart';
import '../habits/habits_screen.dart';
import '../notes/notes_screen.dart';
import '../settings/settings_screen.dart';

/// DOC-034 Part J — More hub: navigation for every module not in the
/// 5-item bottom bar (DOC-033 §10.4).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;

    Widget tile(String icon, String label, Color color, Widget screen) => Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(icon, style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(label, style: textTheme.labelLarge),
                ],
              ),
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1,
            children: [
              tile('↻', 'Habits', semantic.moduleAccent('habits'), const HabitsScreen()),
              tile('🚩', 'Goals', semantic.moduleAccent('goals'), const GoalsScreen()),
              tile('📝', 'Notes', semantic.moduleAccent('notes'), const NotesScreen()),
              tile('📦', 'Assets', semantic.moduleAccent('assets'), const AssetsScreen()),
              tile('📁', 'Documents', semantic.moduleAccent('documents'), const DocumentsScreen()),
              tile('✨', 'Gallery', Theme.of(context).colorScheme.primary, const ComponentGalleryScreen()),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: const Text('Demo Mode: Off'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
