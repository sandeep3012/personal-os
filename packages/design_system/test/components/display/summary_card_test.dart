import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders icon, title, and body', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          body: Text('Net Position: +₹18,200'),
        ),
      ),
    );

    expect(find.text('Finance'), findsOneWidget);
    expect(find.text('Net Position: +₹18,200'), findsOneWidget);
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
  });

  testWidgets('is not wrapped in an InkWell (never navigable)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SummaryCard(
          icon: Icons.account_balance_wallet_outlined,
          accentColor: Colors.blue,
          title: 'Finance',
          body: Text('body'),
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
  });
}
