import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders name, subtitle, and balance', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AccountTile(
          icon: Icons.account_balance_wallet_outlined,
          name: 'Checking',
          subtitle: 'INR',
          balanceText: 'INR 42,000',
        ),
      ),
    );

    expect(find.text('Checking'), findsOneWidget);
    expect(find.text('INR'), findsOneWidget);
    expect(find.text('INR 42,000'), findsOneWidget);
  });

  testWidgets('tap and long-press invoke their callbacks', (tester) async {
    var tapped = false;
    var longPressed = false;
    await tester.pumpWidget(
      _wrap(
        AccountTile(
          icon: Icons.account_balance_wallet_outlined,
          name: 'Checking',
          subtitle: 'INR',
          balanceText: 'INR 42,000',
          onTap: () => tapped = true,
          onLongPress: () => longPressed = true,
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);

    await tester.longPress(find.byType(ListTile));
    expect(longPressed, isTrue);
  });
}
