import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_core/logging/logger.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// The application-level [RuntimeModule].
///
/// Registers the [AppConfig] and the concrete [ILogger] into the service
/// registry. No feature services, no storage, no network.
final class AppModule extends RuntimeModule {
  const AppModule();

  static const AppConfig _config = AppConfig(
    appName: 'Personal OS',
    environment: BuildEnvironment.development,
    version: '0.6.0',
    buildNumber: '1',
  );

  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerSingleton<AppConfig>(_config);
    registrar.registerSingleton<ILogger>(
      const Logger(tag: 'PersonalOS'),
    );
  }
}
