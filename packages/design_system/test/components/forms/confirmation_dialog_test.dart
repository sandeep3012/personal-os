import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the item description in the message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              builder: (context) =>
                  const ConfirmationDialog(itemDescription: 'this account'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text("Delete this account? This can't be undone."), findsOneWidget);
  });

  testWidgets('showConfirmationDialog invokes onConfirm only when confirmed',
      (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showConfirmationDialog(
              context,
              itemDescription: 'this transaction',
              onConfirm: () => confirmed = true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(confirmed, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
  });
}
