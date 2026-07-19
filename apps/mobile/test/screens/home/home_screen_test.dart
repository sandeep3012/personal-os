import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/config/app_config.dart';
import 'package:platform_core/environment/build_environment.dart';
import 'package:personal_os/app/screens/home/home_screen.dart';
import 'package:personal_os/app/theme/app_theme.dart';

const AppConfig _devConfig = AppConfig(
  appName: 'Personal OS',
  environment: BuildEnvironment.development,
  version: '0.5.0',
);

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: child,
    );

void main() {
  group('HomeScreen', () {
    testWidgets('displays app title in app bar', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('Diagnostics'), findsOneWidget);
    });

    testWidgets('shows Platform Status section', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('PLATFORM STATUS'), findsOneWidget);
    });

    testWidgets('shows Platform Core status item', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('Platform Core'), findsOneWidget);
    });

    testWidgets('shows Runtime status item', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('Runtime'), findsOneWidget);
    });

    testWidgets('shows Storage status item', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('Storage'), findsOneWidget);
    });

    testWidgets('shows Version section', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('VERSION'), findsOneWidget);
    });

    testWidgets('shows correct version string', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('v0.5.0'), findsOneWidget);
    });

    testWidgets('shows Current Environment section', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('CURRENT ENVIRONMENT'), findsOneWidget);
    });

    testWidgets('shows environment name uppercased', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.text('DEVELOPMENT'), findsOneWidget);
    });

    testWidgets('shows a check icon for every platform status item',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const HomeScreen(config: _devConfig)));
      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(5));
    });

    testWidgets('displays staging environment correctly',
        (WidgetTester tester) async {
      const stagingConfig = AppConfig(
        appName: 'Personal OS',
        environment: BuildEnvironment.staging,
        version: '0.5.0',
      );
      await tester.pumpWidget(_wrap(const HomeScreen(config: stagingConfig)));
      expect(find.text('STAGING'), findsOneWidget);
    });

    testWidgets('displays custom version correctly',
        (WidgetTester tester) async {
      const v2Config = AppConfig(
        appName: 'Personal OS',
        environment: BuildEnvironment.development,
        version: '1.2.3',
      );
      await tester.pumpWidget(_wrap(const HomeScreen(config: v2Config)));
      expect(find.text('v1.2.3'), findsOneWidget);
    });
  });
}
