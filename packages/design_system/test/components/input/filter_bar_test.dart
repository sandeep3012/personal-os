import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders every filter chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        FilterBar(
          filters: [
            FilterOption(label: 'All', selected: true, onSelected: (_) {}),
            FilterOption(label: 'High', selected: false, onSelected: (_) {}),
          ],
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(2));
  });

  testWidgets('tapping a chip invokes its onSelected', (tester) async {
    bool? selectedTo;
    await tester.pumpWidget(
      _wrap(
        FilterBar(
          filters: [
            FilterOption(
              label: 'High',
              selected: false,
              onSelected: (value) => selectedTo = value,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('High'));
    expect(selectedTo, isTrue);
  });

  testWidgets('shows a More filters chip when onMoreFilters is supplied',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(FilterBar(filters: const [], onMoreFilters: () => tapped = true)),
    );

    expect(find.text('More filters'), findsOneWidget);
    await tester.tap(find.text('More filters'));
    expect(tapped, isTrue);
  });

  testWidgets('omits More filters when onMoreFilters is null', (tester) async {
    await tester.pumpWidget(_wrap(const FilterBar(filters: [])));
    expect(find.text('More filters'), findsNothing);
  });
}
