import 'package:application/application.dart' show AsyncState;
import 'package:decimal/decimal.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden coverage for the design system's visually representative
/// components (TIS §9 "Golden tests"). Scoped to light mode, Compact width,
/// one canonical state per component — dark mode / every breakpoint / every
/// state combination is out of scope for this milestone's golden set (see
/// Milestone 3 report "Technical concerns"); widget tests already cover
/// dark-mode-agnostic behavior and every other state.
Widget _wrap(Widget child) => MaterialApp(
      theme: AppThemeBuilder.build(
        seedColor: const Color(0xFF1565C0),
        brightness: Brightness.light,
      ),
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );

Future<void> _expectGolden(
  WidgetTester tester,
  Widget child,
  String name, {
  Size surfaceSize = const Size(400, 300),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(child));
  await tester.pumpAndSettle();
  await expectLater(find.byType(Scaffold), matchesGoldenFile('golden_files/$name.png'));
}

void main() {
  testWidgets('StatCard', (tester) async {
    await _expectGolden(
      tester,
      const StatCard(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Net Position',
        value: 18200,
        delta: 2.1,
      ),
      'stat_card',
      surfaceSize: const Size(220, 220),
    );
  });

  testWidgets('AccountTile', (tester) async {
    await _expectGolden(
      tester,
      const AccountTile(
        icon: Icons.account_balance_wallet_outlined,
        name: 'Checking',
        subtitle: 'INR',
        balanceText: 'INR 42,000',
      ),
      'account_tile',
      surfaceSize: const Size(400, 120),
    );
  });

  testWidgets('TransactionTile (expense)', (tester) async {
    await _expectGolden(
      tester,
      const TransactionTile(
        type: TransactionTileType.expense,
        title: 'Groceries',
        subtitle: '19 July',
        amountText: '-INR 1,200',
      ),
      'transaction_tile_expense',
      surfaceSize: const Size(400, 120),
    );
  });

  testWidgets('StatusChip tones', (tester) async {
    await _expectGolden(
      tester,
      const Wrap(
        spacing: 8,
        children: [
          StatusChip(label: 'Neutral'),
          StatusChip(label: 'Positive', tone: StatusTone.positive),
          StatusChip(label: 'Negative', tone: StatusTone.negative),
          StatusChip(label: 'Warning', tone: StatusTone.warning),
        ],
      ),
      'status_chip_tones',
      surfaceSize: const Size(400, 160),
    );
  });

  testWidgets('GoalCard', (tester) async {
    await _expectGolden(
      tester,
      const GoalCard(
        name: 'Emergency Fund',
        progress: 0.68,
        progressLabel: '₹68,000 / ₹1,00,000',
      ),
      'goal_card',
      surfaceSize: const Size(400, 180),
    );
  });

  testWidgets('ModuleCard (success)', (tester) async {
    await _expectGolden(
      tester,
      ModuleCard<String>(
        icon: Icons.account_balance_wallet_outlined,
        accentColor: Colors.blue,
        title: 'Finance',
        state: const AsyncState.success('Net Position: +₹18,200'),
        contentBuilder: (context, data) => Text(data),
        onTap: () {},
      ),
      'module_card_success',
      surfaceSize: const Size(400, 180),
    );
  });

  testWidgets('CategorySummaryTile', (tester) async {
    await _expectGolden(
      tester,
      const CategorySummaryTile(
        name: 'Groceries',
        amountText: 'INR 18,200',
        proportion: 0.8,
      ),
      'category_summary_tile',
      surfaceSize: const Size(400, 100),
    );
  });

  testWidgets('MoneyText variants', (tester) async {
    await _expectGolden(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoneyText(
            amount: Decimal.parse('124500'),
            currencyCode: 'INR',
            variant: MoneyTextVariant.display,
          ),
          MoneyText(
            amount: Decimal.parse('-1200'),
            currencyCode: 'INR',
            semantic: MoneySemantic.negative,
          ),
          MoneyText(
            amount: Decimal.parse('5000'),
            currencyCode: 'INR',
            signed: true,
            semantic: MoneySemantic.positive,
          ),
        ],
      ),
      'money_text_variants',
      surfaceSize: const Size(300, 150),
    );
  });
}
