import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:personal_os/app/navigation/app_router.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';

const AppConfig _testConfig = AppConfig(
  appName: 'Personal OS',
  environment: BuildEnvironment.development,
  version: '0.5.0',
);

void main() {
  group('AppRouter', () {
    late GoRouter router;

    setUp(() => router = AppRouter.create(config: _testConfig));
    tearDown(() => router.dispose());

    test('home path constant is "/"', () {
      expect(AppRouter.homePath, '/');
    });

    test('home name constant is "home"', () {
      expect(AppRouter.homeName, 'home');
    });

    test('router has at least one route', () {
      expect(router.configuration.routes, isNotEmpty);
    });

    testWidgets('router initial location is home path', (tester) async {
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    test('create() returns a GoRouter instance', () {
      expect(router, isA<GoRouter>());
    });
  });
}
