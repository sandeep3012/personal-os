import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 200, child: child),
      ),
    );

void main() {
  testWidgets('renders without error at 0, mid, and full value', (tester) async {
    for (final value in [0.0, 0.5, 1.0]) {
      await tester.pumpWidget(_wrap(ProportionBar(value: value)));
      await tester.pumpAndSettle();
      expect(find.byType(ProportionBar), findsOneWidget);
    }
  });

  testWidgets('clamps out-of-range values without throwing', (tester) async {
    await tester.pumpWidget(_wrap(const ProportionBar(value: 2.0)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
