import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Brightness brightness) => MaterialApp(
        theme: AppThemeBuilder.build(
          seedColor: const Color(0xFF1565C0),
          brightness: brightness,
        ),
        home: const ThemeGalleryPage(),
      );

  // The gallery's ListView is long — a tall viewport ensures every section
  // is actually built (slivers only build what's within the viewport +
  // cache extent), so these tests can assert on sections regardless of
  // scroll position rather than scrolling to each one individually.
  Future<void> useTallViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renders every section in light mode without error',
      (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(wrap(Brightness.light));
    await tester.pumpAndSettle();

    expect(find.text('Theme Gallery'), findsOneWidget);
    expect(find.text('Typography'), findsOneWidget);
    expect(find.text('Spacing'), findsOneWidget);
    expect(find.text('Color Scheme'), findsOneWidget);
    expect(find.text('Semantic Colors'), findsOneWidget);
    expect(find.text('Module Accents'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);
    expect(find.text('Chips'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('List Tile'), findsOneWidget);
    expect(find.text('Navigation Bar'), findsOneWidget);
  });

  testWidgets('renders without error in dark mode', (tester) async {
    await useTallViewport(tester);
    await tester.pumpWidget(wrap(Brightness.dark));
    await tester.pumpAndSettle();

    expect(find.text('Theme Gallery'), findsOneWidget);
  });
}
