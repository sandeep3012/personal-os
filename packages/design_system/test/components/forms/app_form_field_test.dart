import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Form(child: child)));

void main() {
  testWidgets('renders the label and hint', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppFormField(label: 'Name', hintText: 'e.g. Checking')),
    );
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('e.g. Checking'), findsOneWidget);
  });

  testWidgets('typing invokes onChanged', (tester) async {
    String? lastValue;
    await tester.pumpWidget(
      _wrap(AppFormField(label: 'Name', onChanged: (v) => lastValue = v)),
    );

    await tester.enterText(find.byType(TextFormField), 'Checking');
    expect(lastValue, 'Checking');
  });

  testWidgets('shows errorText when supplied', (tester) async {
    await tester.pumpWidget(
      _wrap(const AppFormField(label: 'Name', errorText: 'Required')),
    );
    expect(find.text('Required'), findsOneWidget);
  });
}
