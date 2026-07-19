import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders name, category, and expiry chip', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DocumentTile(
          icon: Icons.description_outlined,
          name: 'Car Insurance',
          categoryLabel: 'Insurance',
          expiryLabel: 'Expires in 12 days',
        ),
      ),
    );

    expect(find.text('Car Insurance'), findsOneWidget);
    expect(find.text('Insurance'), findsOneWidget);
    expect(find.text('Expires in 12 days'), findsOneWidget);
  });

  testWidgets('omits the expiry chip when expiryLabel is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const DocumentTile(
          icon: Icons.description_outlined,
          name: 'Passport',
          categoryLabel: 'ID',
        ),
      ),
    );
    expect(find.byType(StatusChip), findsNothing);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _wrap(
        DocumentTile(
          icon: Icons.description_outlined,
          name: 'Passport',
          categoryLabel: 'ID',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    expect(tapped, isTrue);
  });
}
