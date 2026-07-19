import 'package:feature_sample/sample.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:personal_os/app/widgets/section_card.dart';
import 'package:personal_os/app/widgets/status_item.dart';

/// The platform diagnostics screen (shell route `/diagnostics`).
///
/// Not the application's primary destination — Finance is (see
/// [AppRouter]). This screen is a developer-facing view of platform
/// internals:
/// - Platform status (which SDK layers have initialised)
/// - Application version and build environment
/// - Feature navigation (links to registered features)
///
/// Contains no business logic. Data comes from [AppConfig] resolved at startup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics'),
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
                StatusItem(label: 'Application Layer'),
                StatusItem(label: 'Feature Framework'),
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
            SectionCard(
              title: 'FEATURE FRAMEWORK VALIDATION',
              children: [
                Text(
                  'Tap below to navigate to the Sample feature and verify '
                  'the Feature Framework is working end-to-end.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.pushNamed(SampleRoutes.root.name),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Open Sample Feature'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
