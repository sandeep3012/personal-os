import 'package:decimal/decimal.dart';
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
  group('MoneyText.format', () {
    test('groups thousands and keeps two decimal places', () {
      expect(
        MoneyText.format(Decimal.parse('124500'), 'INR'),
        'INR 1,24,500.00',
      );
    });

    test('formats a value under 1000 with no separator', () {
      expect(MoneyText.format(Decimal.parse('42'), 'USD'), 'USD 42.00');
    });

    test('renders a negative amount with a leading minus', () {
      expect(MoneyText.format(Decimal.parse('-1200'), 'INR'), '-INR 1,200.00');
    });

    test('signed:true adds a plus prefix for non-negative amounts', () {
      expect(
        MoneyText.format(Decimal.parse('5000'), 'INR', signed: true),
        '+INR 5,000.00',
      );
    });
  });

  group('MoneyText widget', () {
    testWidgets('renders the formatted amount', (tester) async {
      await tester.pumpWidget(
        _wrap(MoneyText(amount: Decimal.parse('1200'), currencyCode: 'INR')),
      );
      expect(find.text('INR 1,200.00'), findsOneWidget);
    });

    testWidgets('applies the positive semantic color', (tester) async {
      await tester.pumpWidget(
        _wrap(
          MoneyText(
            amount: Decimal.parse('500'),
            currencyCode: 'INR',
            semantic: MoneySemantic.positive,
          ),
        ),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, isNotNull);
    });

    testWidgets('exposes a spoken-form semantics label for negative amounts',
        (tester) async {
      await tester.pumpWidget(
        _wrap(MoneyText(amount: Decimal.parse('-100'), currencyCode: 'INR')),
      );
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.semanticsLabel, contains('minus'));
    });
  });
}
