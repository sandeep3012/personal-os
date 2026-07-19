import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title, subtitle, and amount', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionTile(
          type: TransactionTileType.expense,
          title: 'Groceries',
          subtitle: '19 July',
          amountText: '-INR 1,200',
        ),
      ),
    );

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('19 July'), findsOneWidget);
    expect(find.text('-INR 1,200'), findsOneWidget);
  });

  testWidgets('expense shows a down arrow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionTile(
          type: TransactionTileType.expense,
          title: 'Groceries',
          subtitle: 'note',
          amountText: '-100',
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('income shows an up arrow', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionTile(
          type: TransactionTileType.income,
          title: 'Salary',
          subtitle: 'note',
          amountText: '+100',
        ),
      ),
    );
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('transfer shows a swap icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionTile(
          type: TransactionTileType.transfer,
          title: 'Transfer',
          subtitle: 'note',
          amountText: '100',
        ),
      ),
    );
    expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
  });

  testWidgets('is not dismissible when onDismissed is not supplied',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const TransactionTile(
          type: TransactionTileType.expense,
          title: 'Groceries',
          subtitle: 'note',
          amountText: '-100',
        ),
      ),
    );
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets('swiping a dismissible tile invokes onDismissed', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        TransactionTile(
          type: TransactionTileType.expense,
          title: 'Groceries',
          subtitle: 'note',
          amountText: '-100',
          dismissKey: const ValueKey('txn-1'),
          onDismissed: () => dismissed = true,
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });

  test('asserts dismissKey is required when onDismissed is supplied', () {
    expect(
      () => TransactionTile(
        type: TransactionTileType.expense,
        title: 'Groceries',
        subtitle: 'note',
        amountText: '-100',
        onDismissed: () {},
      ),
      throwsAssertionError,
    );
  });
}
