import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoints.fromWidth', () {
    test('below 600 is compact', () {
      expect(AppBreakpoints.fromWidth(599), AppWindowSizeClass.compact);
      expect(AppBreakpoints.fromWidth(0), AppWindowSizeClass.compact);
    });

    test('600 to 839 is medium', () {
      expect(AppBreakpoints.fromWidth(600), AppWindowSizeClass.medium);
      expect(AppBreakpoints.fromWidth(839), AppWindowSizeClass.medium);
    });

    test('840 and above is expanded', () {
      expect(AppBreakpoints.fromWidth(840), AppWindowSizeClass.expanded);
      expect(AppBreakpoints.fromWidth(2000), AppWindowSizeClass.expanded);
    });
  });

  group('AppBreakpoints.of', () {
    testWidgets('reads the size class from MediaQuery width', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 800)),
          child: Builder(
            builder: (context) {
              expect(AppBreakpoints.of(context), AppWindowSizeClass.expanded);
              expect(AppBreakpoints.isAtLeastMedium(context), isTrue);
              expect(AppBreakpoints.isExpanded(context), isTrue);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('compact width is neither medium nor expanded',
        (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              expect(AppBreakpoints.of(context), AppWindowSizeClass.compact);
              expect(AppBreakpoints.isAtLeastMedium(context), isFalse);
              expect(AppBreakpoints.isExpanded(context), isFalse);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
