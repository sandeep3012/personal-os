import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title, message, and icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No accounts yet',
          message: 'Track where your money lives',
        ),
      ),
    );

    expect(find.text('No accounts yet'), findsOneWidget);
    expect(find.text('Track where your money lives'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('omits the action button when none is supplied', (tester) async {
    await tester.pumpWidget(
      _wrap(const EmptyState(icon: Icons.inbox_outlined, title: 'Empty')),
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('tapping the action button invokes onAction', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Empty',
          actionLabel: 'Add Account',
          onAction: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Add Account'));
    expect(tapped, isTrue);
  });
}
