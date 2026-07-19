import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppThemeBuilder.build(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders the label', (tester) async {
    await tester.pumpWidget(_wrap(const StatusChip(label: 'High')));
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('renders an icon when supplied', (tester) async {
    await tester.pumpWidget(
      _wrap(const StatusChip(label: 'Overdue', icon: Icons.warning_amber)),
    );
    expect(find.byIcon(Icons.warning_amber), findsOneWidget);
  });

  for (final tone in StatusTone.values) {
    testWidgets('renders without error for tone $tone', (tester) async {
      await tester.pumpWidget(_wrap(StatusChip(label: 'Label', tone: tone)));
      expect(find.byType(Chip), findsOneWidget);
    });
  }
}
