import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders only the primary FAB when there are no secondary actions',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        FloatingActionMenu(
          primary: FloatingActionMenuAction(
            icon: Icons.add,
            label: 'Add Expense',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Add Expense'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    expect(tapped, isTrue);
  });

  testWidgets('compact mode opens a bottom sheet listing secondary actions',
      (tester) async {
    var incomeTapped = false;
    await tester.pumpWidget(
      _wrap(
        FloatingActionMenu(
          primary: FloatingActionMenuAction(
            icon: Icons.remove,
            label: 'Add Expense',
            onTap: () {},
          ),
          secondaryActions: [
            FloatingActionMenuAction(
              icon: Icons.add,
              label: 'Add Income',
              onTap: () => incomeTapped = true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Add Income'), findsNothing);

    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    expect(find.text('Add Income'), findsOneWidget);
    await tester.tap(find.text('Add Income'));
    await tester.pumpAndSettle();

    expect(incomeTapped, isTrue);
  });

  testWidgets('non-compact mode renders secondary actions inline', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FloatingActionMenu(
          compact: false,
          primary: FloatingActionMenuAction(
            icon: Icons.remove,
            label: 'Add Expense',
            onTap: () {},
          ),
          secondaryActions: [
            FloatingActionMenuAction(icon: Icons.add, label: 'Add Income', onTap: () {}),
          ],
        ),
      ),
    );

    expect(find.text('Add Income'), findsOneWidget);
    expect(find.byTooltip('More actions'), findsNothing);
  });
}
