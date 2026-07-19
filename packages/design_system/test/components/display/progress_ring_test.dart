import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the label', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressRing(progress: 0.68, label: '68%')));
    await tester.pumpAndSettle();
    expect(find.text('68%'), findsOneWidget);
  });

  testWidgets('clamps progress above 1 to 1', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressRing(progress: 1.5)));
    await tester.pumpAndSettle();
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, 1.0);
  });

  testWidgets('clamps negative progress to 0', (tester) async {
    await tester.pumpWidget(_wrap(const ProgressRing(progress: -0.2)));
    await tester.pumpAndSettle();
    final indicator = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(indicator.value, 0.0);
  });
}
