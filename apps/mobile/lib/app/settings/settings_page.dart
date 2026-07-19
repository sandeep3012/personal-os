import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';

/// The Settings branch's landing screen (Milestone 6 Part E), currently
/// responsible only for Demo Mode management — Profile/Theme/Backup/
/// Diagnostics/Developer Options/About remain out of scope (TIS §2).
final class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.demoModeController});

  final DemoModeController demoModeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: demoModeController,
        builder: (context, _) => ListView(
          children: [
            SectionHeader(
              title: 'Demo Mode',
              trailing: StatusChip(
                label: demoModeController.isDemoMode ? 'Active' : 'Off',
                tone: demoModeController.isDemoMode
                    ? StatusTone.positive
                    : StatusTone.neutral,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                demoModeController.isDemoMode
                    ? "You're exploring with sample data. Your real data is "
                        'untouched and safe.'
                    : 'Explore the app with realistic sample data without '
                        'creating anything real.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!demoModeController.isDemoMode)
              ListTile(
                leading: const Icon(Icons.science_outlined),
                title: const Text('Enable Demo Mode'),
                subtitle: const Text('Load realistic sample Finance data'),
                onTap: demoModeController.enableDemoMode,
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Demo Data'),
                subtitle: const Text('Discard and reload fresh sample data'),
                onTap: () => showConfirmationDialog(
                  context,
                  title: 'Reset Demo Data',
                  itemDescription: 'the current demo data',
                  confirmLabel: 'Reset',
                  onConfirm: demoModeController.resetDemoData,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app),
                title: const Text('Exit Demo Mode'),
                subtitle: const Text('Return to your real data'),
                onTap: demoModeController.exitDemoMode,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
