import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders name, value, and delta', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AssetTile(
          icon: Icons.house_outlined,
          name: 'House',
          valueText: '₹35,00,000',
          deltaLabel: '+2.1%',
          deltaPositive: true,
        ),
      ),
    );

    expect(find.text('House'), findsOneWidget);
    expect(find.text('₹35,00,000'), findsOneWidget);
    expect(find.text('+2.1%'), findsOneWidget);
  });

  testWidgets('omits the delta line when deltaLabel is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const AssetTile(
          icon: Icons.house_outlined,
          name: 'House',
          valueText: '₹35,00,000',
        ),
      ),
    );
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        AssetTile(
          icon: Icons.house_outlined,
          name: 'House',
          valueText: '₹1',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
