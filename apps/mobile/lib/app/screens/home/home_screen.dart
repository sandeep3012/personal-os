import 'package:flutter/material.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:personal_os/app/widgets/section_card.dart';
import 'package:personal_os/app/widgets/status_item.dart';

/// The application home screen — the shell's single route ("/").
///
/// Displays:
/// - Platform status (which SDK layers have initialized)
/// - Application version
/// - Current build environment
///
/// Contains no business logic. All data comes from [AppConfig] which is
/// resolved from the service registry at startup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal OS'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            const SectionCard(
              title: 'PLATFORM STATUS',
              children: [
                StatusItem(label: 'Platform Core'),
                StatusItem(label: 'Runtime'),
                StatusItem(label: 'Storage'),
              ],
            ),
            SectionCard(
              title: 'VERSION',
              children: [
                Text(
                  'v${config.version}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            SectionCard(
              title: 'CURRENT ENVIRONMENT',
              children: [
                Text(
                  config.environment.name.toUpperCase(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
