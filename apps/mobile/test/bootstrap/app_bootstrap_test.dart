import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:platform_core/logging/i_logger.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';

void main() {
  group('AppBootstrap', () {
    test('boot() completes without error', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.isBooted, isTrue);
      expect(bootstrap.isShutdown, isFalse);
      await bootstrap.shutdown();
    });

    test('registry has ILogger registered after boot', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.registry.isRegistered<ILogger>(), isTrue);
      await bootstrap.shutdown();
    });

    test('registry has AppConfig registered after boot', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.registry.isRegistered<AppConfig>(), isTrue);
      await bootstrap.shutdown();
    });

    test('config has correct app name', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.config.appName, 'Personal OS');
      await bootstrap.shutdown();
    });

    test('config has development environment', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.config.environment, BuildEnvironment.development);
      await bootstrap.shutdown();
    });

    test('config has version 0.5.0', () async {
      final bootstrap = await AppBootstrap.boot();
      expect(bootstrap.config.version, '0.5.0');
      await bootstrap.shutdown();
    });

    test('shutdown() completes without error', () async {
      final bootstrap = await AppBootstrap.boot();
      await expectLater(bootstrap.shutdown(), completes);
      expect(bootstrap.isShutdown, isTrue);
    });

    test('ILogger can log without throwing', () async {
      final bootstrap = await AppBootstrap.boot();
      final logger = bootstrap.registry.get<ILogger>();
      expect(
        () {
          logger.info('test message');
          logger.debug('debug message');
          logger.warning('warning message');
        },
        returnsNormally,
      );
      await bootstrap.shutdown();
    });
  });
}
