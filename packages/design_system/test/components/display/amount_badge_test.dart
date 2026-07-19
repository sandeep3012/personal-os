import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppThemeBuilder.build(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the count', (tester) async {
    await tester.pumpWidget(_wrap(const AmountBadge(count: 3)));
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('renders nothing when count is zero', (tester) async {
    await tester.pumpWidget(_wrap(const AmountBadge(count: 0)));
    expect(find.byType(Container), findsNothing);
  });

  testWidgets('renders nothing when count is negative', (tester) async {
    await tester.pumpWidget(_wrap(const AmountBadge(count: -1)));
    expect(find.text('-1'), findsNothing);
  });
}
