import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders name, amount, and a ProportionBar', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const CategorySummaryTile(
          name: 'Groceries',
          amountText: 'INR 18,200',
          proportion: 0.8,
        ),
      ),
    );

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('INR 18,200'), findsOneWidget);
    expect(find.byType(ProportionBar), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        CategorySummaryTile(
          name: 'Groceries',
          amountText: 'INR 100',
          proportion: 0.5,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
