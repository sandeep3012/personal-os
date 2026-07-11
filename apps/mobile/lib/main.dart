import 'package:flutter/widgets.dart';
import 'package:personal_os/app.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';

/// Entry point for Personal OS.
///
/// Ensures Flutter bindings are ready, then delegates to [_runApp] which
/// boots the platform runtime and starts the widget tree.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runApp();
}

/// Boots the platform runtime and runs the application.
///
/// On success: mounts [PersonalOsApp] with the booted [AppBootstrap].
/// On failure: mounts [BootFailureApp] with the error message and a retry
///             callback that re-invokes [_runApp].
Future<void> _runApp() async {
  try {
    final bootstrap = await AppBootstrap.boot();
    runApp(PersonalOsApp(bootstrap: bootstrap));
  } catch (e) {
    runApp(
      BootFailureApp(
        errorMessage: e.toString(),
        onRetry: _runApp,
      ),
    );
  }
}
