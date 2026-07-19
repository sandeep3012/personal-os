import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the hint text', (tester) async {
    await tester.pumpWidget(
      _wrap(AppSearchBar(hintText: 'Search categories', onChanged: (_) {})),
    );
    expect(find.text('Search categories'), findsOneWidget);
  });

  testWidgets('typing invokes onChanged', (tester) async {
    String? lastValue;
    await tester.pumpWidget(
      _wrap(AppSearchBar(onChanged: (value) => lastValue = value)),
    );

    await tester.enterText(find.byType(SearchBar), 'food');
    expect(lastValue, 'food');
  });

  testWidgets('clear button appears and clears the controller', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? lastValue = 'unset';

    await tester.pumpWidget(
      _wrap(
        AppSearchBar(controller: controller, onChanged: (value) => lastValue = value),
      ),
    );

    expect(find.byTooltip('Clear search'), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'food');
    await tester.pump();
    expect(find.byTooltip('Clear search'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(lastValue, isEmpty);
  });
}
