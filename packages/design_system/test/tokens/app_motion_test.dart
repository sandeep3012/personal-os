import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppMotion durations', () {
    test('fast < standard < page < celebration', () {
      expect(AppMotion.fast.inMilliseconds, lessThan(AppMotion.standard.inMilliseconds));
      expect(
        AppMotion.standard.inMilliseconds,
        lessThan(AppMotion.page.inMilliseconds),
      );
      expect(
        AppMotion.page.inMilliseconds,
        lessThan(AppMotion.celebration.inMilliseconds),
      );
    });

    test('standard durations stay under 300ms except celebration', () {
      expect(AppMotion.fast.inMilliseconds, lessThanOrEqualTo(300));
      expect(AppMotion.standard.inMilliseconds, lessThanOrEqualTo(300));
      expect(AppMotion.page.inMilliseconds, lessThanOrEqualTo(300));
    });
  });

  group('AppMotion.durationOrZero', () {
    testWidgets('returns the duration when animations are not disabled',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: false),
          child: Builder(
            builder: (context) {
              expect(
                AppMotion.durationOrZero(context, AppMotion.standard),
                AppMotion.standard,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('returns zero when reduced motion is enabled', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(
            builder: (context) {
              expect(
                AppMotion.durationOrZero(context, AppMotion.standard),
                Duration.zero,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
