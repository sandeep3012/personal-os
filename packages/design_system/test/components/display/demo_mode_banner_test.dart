import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders nothing when moduleNames is empty', (tester) async {
    await tester.pumpWidget(_wrap(const DemoModeBanner(moduleNames: [])));
    expect(find.byIcon(Icons.science_outlined), findsNothing);
    expect(find.textContaining("You're viewing sample data"), findsNothing);
  });

  testWidgets('lists every module name in the message', (tester) async {
    await tester.pumpWidget(
      _wrap(const DemoModeBanner(moduleNames: ['Finance', 'Tasks'])),
    );
    expect(find.textContaining('Finance, Tasks'), findsOneWidget);
  });

  testWidgets('tapping dismiss invokes onDismiss', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        DemoModeBanner(
          moduleNames: const ['Finance'],
          onDismiss: () => dismissed = true,
        ),
      ),
    );

    await tester.tap(find.byTooltip('Dismiss'));
    expect(dismissed, isTrue);
  });

  testWidgets('tapping Add real data invokes onAddRealData', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        DemoModeBanner(
          moduleNames: const ['Finance'],
          onAddRealData: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('Add real data'));
    expect(tapped, isTrue);
  });
}
