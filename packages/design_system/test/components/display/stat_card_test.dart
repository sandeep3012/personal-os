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
  testWidgets('renders the label and formatted value', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Net Position',
          value: 18200,
          valueFormatter: (v) => '₹${v.round()}',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Net Position'), findsOneWidget);
    expect(find.text('₹18200'), findsOneWidget);
  });

  testWidgets('animates the value from 0 on first appearance', (tester) async {
    await tester.pumpWidget(
      _wrap(
        StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Net Position',
          value: 100,
          valueFormatter: (v) => v.round().toString(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('0'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('shows the delta with an up arrow when positive', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Net Position',
          value: 100,
          delta: 2.1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.text('+2.1%'), findsOneWidget);
  });

  testWidgets('shows the delta with a down arrow when negative', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Net Position',
          value: 100,
          delta: -1.4,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.text('-1.4%'), findsOneWidget);
  });

  testWidgets('omits the delta row when delta is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Net Position',
          value: 100,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_upward), findsNothing);
    expect(find.byIcon(Icons.arrow_downward), findsNothing);
  });
}
