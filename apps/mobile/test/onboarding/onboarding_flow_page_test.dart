import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/onboarding/onboarding_flow_page.dart';

Widget _buildPage({
  required Future<void> Function() onStartFresh,
  required Future<void> Function() onEnableDemoMode,
}) =>
    MaterialApp(
      home: OnboardingFlowPage(
        onStartFresh: onStartFresh,
        onEnableDemoMode: onEnableDemoMode,
      ),
    );

void main() {
  group('OnboardingFlowPage — first launch', () {
    testWidgets('starts on the Welcome screen', (tester) async {
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async {},
        onEnableDemoMode: () async {},
      ));

      expect(find.text('Welcome to Personal OS'), findsOneWidget);
    });

    testWidgets('Next advances through Welcome -> Feature overview -> Get '
        'Started (max 3 screens)', (tester) async {
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async {},
        onEnableDemoMode: () async {},
      ));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('What you can do'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('How would you like to start?'), findsOneWidget);

      // No further "Next" — this is the last of exactly 3 screens.
      expect(find.text('Next'), findsNothing);
    });
  });

  group('OnboardingFlowPage — skip', () {
    testWidgets('tapping Skip on the Welcome screen invokes onStartFresh',
        (tester) async {
      var startFreshCalled = false;
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async => startFreshCalled = true,
        onEnableDemoMode: () async {},
      ));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(startFreshCalled, isTrue);
    });

    testWidgets('Skip is not shown on the final (Get Started) screen',
        (tester) async {
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async {},
        onEnableDemoMode: () async {},
      ));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Visibility(maintainState: true) keeps the Skip button in the tree
      // but invisible/non-interactive — assert on its hitTestable form.
      expect(find.text('Skip').hitTestable(), findsNothing);
    });
  });

  group('OnboardingFlowPage — Start Fresh', () {
    testWidgets('tapping Start Fresh on the last screen invokes onStartFresh',
        (tester) async {
      var startFreshCalled = false;
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async => startFreshCalled = true,
        onEnableDemoMode: () async {},
      ));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Fresh'));
      await tester.pumpAndSettle();

      expect(startFreshCalled, isTrue);
    });
  });

  group('OnboardingFlowPage — Demo Mode selection', () {
    testWidgets(
        'tapping "Explore with Demo Mode" on the last screen invokes '
        'onEnableDemoMode', (tester) async {
      var demoModeCalled = false;
      await tester.pumpWidget(_buildPage(
        onStartFresh: () async {},
        onEnableDemoMode: () async => demoModeCalled = true,
      ));

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore with Demo Mode'));
      await tester.pumpAndSettle();

      expect(demoModeCalled, isTrue);
    });
  });
}
