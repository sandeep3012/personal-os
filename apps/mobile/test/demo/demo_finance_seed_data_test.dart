import 'package:feature_finance/finance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/demo/demo_finance_seed_data.dart';

const _ws = 'ws-seed-test';

void main() {
  group('DemoFinanceSeedData', () {
    test('seeds a cash, savings, and credit card account with realistic '
        'names — never placeholder names', () async {
      final executor = InMemoryFinanceDatabaseExecutor();

      await DemoFinanceSeedData.seed(executor, workspaceId: _ws);

      final accounts = await executor.query(
        'SELECT * FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );
      expect(accounts, hasLength(3));

      final types = accounts.map((a) => a['account_type']).toSet();
      expect(types, {'cash', 'savings', 'creditCard'});

      final names = accounts.map((a) => a['name'] as String).toSet();
      for (final placeholder in ['Account A', 'Account B', 'John Doe', 'Sample']) {
        expect(names.any((n) => n.contains(placeholder)), isFalse);
      }
    });

    test('covers every required category across income, expense, and '
        'transfer transactions', () async {
      final executor = InMemoryFinanceDatabaseExecutor();

      await DemoFinanceSeedData.seed(executor, workspaceId: _ws);

      final transactions = await executor.query(
        'SELECT * FROM transactions WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );
      expect(transactions.length, greaterThanOrEqualTo(15));

      final categories = transactions
          .map((t) => t['category_id'])
          .whereType<String>()
          .toSet();
      expect(
        categories,
        containsAll(<String>[
          'Salary',
          'Food',
          'Fuel',
          'Shopping',
          'Entertainment',
          'Utilities',
          'Medical',
          'Travel',
          'Miscellaneous',
        ]),
      );

      final types = transactions.map((t) => t['transaction_type']).toSet();
      expect(types, containsAll(<String>['income', 'expense']));

      // Realistic merchants/payees, not placeholders.
      final payees = transactions.map((t) => t['payee']).whereType<String>().toSet();
      expect(payees, isNotEmpty);
      for (final placeholder in ['Merchant 1', 'Payee A', 'John Doe']) {
        expect(payees.any((p) => p.contains(placeholder)), isFalse);
      }

      // Dates vary — not every transaction on the same day.
      final dates = transactions.map((t) => t['transaction_date']).toSet();
      expect(dates.length, greaterThan(1));
    });

    test('includes exactly one linked transfer pair', () async {
      final executor = InMemoryFinanceDatabaseExecutor();

      await DemoFinanceSeedData.seed(executor, workspaceId: _ws);

      final transactions = await executor.query(
        'SELECT * FROM transactions WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );
      final withPair =
          transactions.where((t) => t['transfer_pair_id'] != null).toList();
      expect(withPair, hasLength(2));

      final ids = withPair.map((t) => t['transaction_id']).toSet();
      final pairIds = withPair.map((t) => t['transfer_pair_id']).toSet();
      expect(pairIds, ids); // each leg's pair id points at the other leg
      expect(withPair[0]['amount_minor'], withPair[1]['amount_minor']);
      expect(withPair.map((t) => t['account_id']).toSet(), hasLength(2));
    });

    test('resets to an identical fresh dataset when seeded again', () async {
      final first = InMemoryFinanceDatabaseExecutor();
      await DemoFinanceSeedData.seed(first, workspaceId: _ws);
      final firstAccounts = await first.query(
        'SELECT * FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );

      final second = InMemoryFinanceDatabaseExecutor();
      await DemoFinanceSeedData.seed(second, workspaceId: _ws);
      final secondAccounts = await second.query(
        'SELECT * FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL',
        [_ws],
      );

      expect(secondAccounts.length, firstAccounts.length);
      expect(
        secondAccounts.map((a) => a['account_id']).toSet(),
        firstAccounts.map((a) => a['account_id']).toSet(),
      );
    });
  });
}
