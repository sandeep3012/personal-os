import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the title', (tester) async {
    await tester.pumpWidget(_wrap(const SectionHeader(title: 'Accounts')));
    expect(find.text('Accounts'), findsOneWidget);
  });

  testWidgets('shows a See all button when onSeeAll is supplied', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(SectionHeader(title: 'Accounts', onSeeAll: () => tapped = true)),
    );

    await tester.tap(find.text('See all'));
    expect(tapped, isTrue);
  });

  testWidgets('trailing widget takes precedence over onSeeAll', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SectionHeader(
          title: 'Accounts',
          onSeeAll: () {},
          trailing: const Icon(Icons.filter_list),
        ),
      ),
    );

    expect(find.byIcon(Icons.filter_list), findsOneWidget);
    expect(find.text('See all'), findsNothing);
  });

  testWidgets('is marked as a semantic header', (tester) async {
    await tester.pumpWidget(_wrap(const SectionHeader(title: 'Accounts')));

    final semanticsWidgets = tester.widgetList<Semantics>(find.byType(Semantics));
    expect(semanticsWidgets.any((s) => s.properties.header == true), isTrue);
  });
}
