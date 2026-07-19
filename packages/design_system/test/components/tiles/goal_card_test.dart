import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders name and progress label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GoalCard(
          name: 'Emergency Fund',
          progress: 0.68,
          progressLabel: '₹68,000 / ₹1,00,000',
        ),
      ),
    );

    expect(find.text('Emergency Fund'), findsOneWidget);
    expect(find.text('₹68,000 / ₹1,00,000'), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        GoalCard(
          name: 'Emergency Fund',
          progress: 0.68,
          progressLabel: 'label',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(GoalCard));
    expect(tapped, isTrue);
  });
}
