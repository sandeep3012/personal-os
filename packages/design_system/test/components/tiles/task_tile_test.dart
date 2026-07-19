import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the title and priority chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TaskTile(
          title: 'Pay electricity bill',
          completed: false,
          onToggle: (_) {},
          priorityLabel: 'High',
          priorityTone: StatusTone.negative,
        ),
      ),
    );

    expect(find.text('Pay electricity bill'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('applies strikethrough when completed', (tester) async {
    await tester.pumpWidget(
      _wrap(TaskTile(title: 'Buy groceries', completed: true, onToggle: (_) {})),
    );

    final text = tester.widget<Text>(find.text('Buy groceries'));
    expect(text.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('tapping the checkbox invokes onToggle', (tester) async {
    bool? toggledTo;
    await tester.pumpWidget(
      _wrap(
        TaskTile(
          title: 'Buy groceries',
          completed: false,
          onToggle: (value) => toggledTo = value,
        ),
      ),
    );

    await tester.tap(find.byType(Checkbox));
    expect(toggledTo, isTrue);
  });

  testWidgets('swiping a dismissible task invokes onDismissed', (tester) async {
    var dismissed = false;
    await tester.pumpWidget(
      _wrap(
        TaskTile(
          title: 'Buy groceries',
          completed: false,
          onToggle: (_) {},
          dismissKey: const ValueKey('task-1'),
          onDismissed: () => dismissed = true,
        ),
      ),
    );

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
  });
}
