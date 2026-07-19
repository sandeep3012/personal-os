import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title and child content', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppBottomSheetForm(
          title: 'Add Transaction',
          onSave: () {},
          child: const Text('form fields here'),
        ),
      ),
    );

    expect(find.text('Add Transaction'), findsOneWidget);
    expect(find.text('form fields here'), findsOneWidget);
  });

  testWidgets('tapping Save invokes onSave', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      _wrap(
        AppBottomSheetForm(
          title: 'Add Transaction',
          onSave: () => saved = true,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    expect(saved, isTrue);
  });
}
