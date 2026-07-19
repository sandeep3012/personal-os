import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the icon and label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuickActionButton(
          icon: Icons.add,
          label: 'Add Expense',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        QuickActionButton(icon: Icons.add, label: 'Add', onTap: () => tapped = true),
      ),
    );

    await tester.tap(find.byType(QuickActionButton));
    expect(tapped, isTrue);
  });

  testWidgets('meets the 48dp minimum tap target', (tester) async {
    await tester.pumpWidget(
      _wrap(QuickActionButton(icon: Icons.add, label: 'Add', onTap: () {})),
    );

    await expectLater(
      tester,
      meetsGuideline(androidTapTargetGuideline),
    );
  });
}
