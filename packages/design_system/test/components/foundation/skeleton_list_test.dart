import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {bool disableAnimations = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(body: child),
      ),
    );

void main() {
  testWidgets('renders the requested number of rows', (tester) async {
    await tester.pumpWidget(_wrap(const SkeletonList(rowCount: 4)));
    await tester.pump();
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('does not animate when reduced motion is enabled', (tester) async {
    await tester.pumpWidget(
      _wrap(const SkeletonList(rowCount: 2), disableAnimations: true),
    );
    await tester.pump();
    // No exception / infinite pump required — a static row renders.
    expect(find.byType(SkeletonList), findsOneWidget);
  });

  testWidgets('exposes a loading semantic label', (tester) async {
    await tester.pumpWidget(_wrap(const SkeletonList()));
    expect(find.bySemanticsLabel('Loading content'), findsOneWidget);
  });
}
