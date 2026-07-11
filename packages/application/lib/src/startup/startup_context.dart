import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_service_locator.dart';

/// Carries the resolved application context through a [StartupPipeline].
///
/// Each [StartupStep] receives a [StartupContext] so that steps can read
/// configuration and resolve already-registered services without depending on
/// global state.
///
/// [StartupContext] is constructed by the application bootstrap layer after the
/// runtime has been booted and the service registry is populated.
final class StartupContext {
  const StartupContext({
    required this.locator,
    required this.config,
  });

  /// The fully populated service registry from the runtime bootstrap.
  final IServiceLocator locator;

  /// The application configuration resolved during startup.
  final AppConfig config;
}
