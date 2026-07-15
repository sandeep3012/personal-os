import 'package:feature_sample/src/application/sample_service.dart';
import 'package:flutter/material.dart';

/// The sole screen of the Sample feature.
///
/// Displays the current [SampleService.status] string. After a successful
/// startup the message reads "Sample Feature Loaded Successfully".
///
/// This screen exists only to validate the Feature Framework end-to-end.
/// It contains no business logic.
class SamplePage extends StatelessWidget {
  const SamplePage({super.key, required this.service});

  final SampleService service;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Feature'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  service.isLoaded
                      ? Icons.check_circle_outline
                      : Icons.hourglass_empty,
                  size: 64,
                  color: service.isLoaded
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(height: 24),
                Text(
                  service.status,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Framework validation reference feature',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
