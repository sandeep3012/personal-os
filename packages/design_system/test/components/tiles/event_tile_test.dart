import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the date label, title, and amount', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EventTile(
          dateLabel: 'Tomorrow',
          title: 'Electricity bill',
          amountText: 'INR 1,800',
        ),
      ),
    );

    expect(find.text('Tomorrow'), findsOneWidget);
    expect(find.text('Electricity bill'), findsOneWidget);
    expect(find.text('INR 1,800'), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EventTile(
          dateLabel: 'Today',
          title: 'Dentist',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(InkWell));
    expect(tapped, isTrue);
  });
}
