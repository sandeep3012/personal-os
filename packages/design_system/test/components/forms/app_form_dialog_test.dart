import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title and child content', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFormDialog(
          title: 'Add Account',
          onSave: () {},
          child: const Text('form fields here'),
        ),
      ),
    );

    expect(find.text('Add Account'), findsOneWidget);
    expect(find.text('form fields here'), findsOneWidget);
  });

  testWidgets('tapping Save invokes onSave', (tester) async {
    var saved = false;
    await tester.pumpWidget(
      _wrap(
        AppFormDialog(
          title: 'Add Account',
          onSave: () => saved = true,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    expect(saved, isTrue);
  });

  testWidgets('custom saveLabel and cancelLabel render', (tester) async {
    await tester.pumpWidget(
      _wrap(
        AppFormDialog(
          title: 'Add Account',
          onSave: () {},
          saveLabel: 'Create',
          cancelLabel: 'Discard',
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });
}
