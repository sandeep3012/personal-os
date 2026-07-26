import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import '../../shared/widgets/confirm_dialog.dart';

/// DOC-034 Part K — Settings. Grouped sections, denser layout permitted.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _demoMode = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget sectionLabel(String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            text,
            style: textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 1.1),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          sectionLabel('APPEARANCE'),
          Card(
            child: ListTile(
              title: const Text('Theme'),
              trailing: const Text('System'),
              onTap: () {},
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          sectionLabel('DEMO MODE'),
          Card(
            child: SwitchListTile(
              title: const Text('Demo Mode'),
              subtitle: const Text('See sample data without affecting your real data.'),
              value: _demoMode,
              onChanged: (v) => setState(() => _demoMode = v),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _demoMode
                ? () => showAppConfirmDialog(
                      context: context,
                      title: 'Reset Demo Data?',
                      message: 'This discards any changes to sample data.',
                      confirmLabel: 'Reset',
                    )
                : null,
            child: const Text('Reset Demo Data'),
          ),
          const SizedBox(height: AppSpacing.lg),
          sectionLabel('ABOUT'),
          const Card(child: ListTile(title: Text('Version'), trailing: Text('0.6.0'))),
        ],
      ),
    );
  }
}
