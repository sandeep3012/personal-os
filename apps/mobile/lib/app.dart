import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';
import 'package:personal_os/app/navigation/app_router.dart';
import 'package:personal_os/app/theme/app_theme.dart';

/// The root widget of Personal OS.
///
/// Receives a fully booted [AppBootstrap] and constructs the router and
/// Material 3 app. Listens to [AppLifecycleState.detached] to trigger a
/// graceful runtime shutdown.
class PersonalOsApp extends StatefulWidget {
  const PersonalOsApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<PersonalOsApp> createState() => _PersonalOsAppState();
}

class _PersonalOsAppState extends State<PersonalOsApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = AppRouter.create(config: widget.bootstrap.config);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(widget.bootstrap.shutdown());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Personal OS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

/// Shown when [AppBootstrap.boot] throws an exception.
///
/// Displays the error message and a retry button that re-runs the bootstrap
/// sequence.
class BootFailureApp extends StatelessWidget {
  const BootFailureApp({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal OS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Platform failed to initialize',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async => onRetry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
