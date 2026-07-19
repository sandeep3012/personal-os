import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_net_position_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_expenses_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:feature_finance/src/presentation/pages/finance_home_page.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

const _ws = 'ws-1';
final _inr = CurrencyCode('INR');

Account _account(String id, {String name = 'Account'}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: name,
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.parse('1000'), currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness()
      : accountRepo = FakeAccountRepository(),
        txnRepo = FakeTransactionRepository() {
    viewModel = FinanceHomeViewModel(
      getAccountsUseCase: GetAccountsUseCase(accountRepository: accountRepo),
      getAccountBalanceUseCase: GetAccountBalanceUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
        balanceCalculationService: const BalanceCalculationService(),
      ),
      getTotalIncomeUseCase: GetTotalIncomeUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      getTotalExpensesUseCase: GetTotalExpensesUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      getNetPositionUseCase: GetNetPositionUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      queryTransactionsUseCase: QueryTransactionsUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeAccountRepository accountRepo;
  final FakeTransactionRepository txnRepo;
  late final FinanceHomeViewModel viewModel;

  Widget buildPage({VoidCallback? onOpenAccounts, VoidCallback? onOpenTransactions}) =>
      MaterialApp(
        home: FinanceHomePage(
          viewModel: viewModel,
          navCallbacks: FinanceNavCallbacks(
            onOpenAccounts: onOpenAccounts,
            onOpenTransactions: onOpenTransactions,
          ),
        ),
      );
}

void main() {
  group('FinanceHomePage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no accounts exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('shows summary cards and account overview after loading',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1', name: 'Savings')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Net Position (this month)'), findsOneWidget);
    });
  });

  group('FinanceHomePage — recent transactions', () {
    testWidgets('shows "No recent transactions" when there are none',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No recent transactions'), findsOneWidget);
    });
  });

  group('FinanceHomePage — quick actions', () {
    testWidgets('tapping "View Accounts" invokes onOpenAccounts', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      var tapped = false;
      await tester.pumpWidget(harness.buildPage(onOpenAccounts: () => tapped = true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Accounts'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('tapping "View Transactions" invokes onOpenTransactions',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      var tapped = false;
      await tester.pumpWidget(
        harness.buildPage(onOpenTransactions: () => tapped = true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Transactions'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('quick action buttons are absent when no callback is supplied',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('View Accounts'), findsNothing);
      expect(find.text('View Transactions'), findsNothing);
    });
  });

  group('FinanceHomePage — navigation drawer', () {
    testWidgets('no drawer icon is shown when navCallbacks is null',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(
        MaterialApp(home: FinanceHomePage(viewModel: harness.viewModel)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.menu), findsNothing);
    });

    testWidgets(
        'opening the drawer shows Dashboard/Accounts/Transactions/'
        'Categories/Diagnostics entries', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(
        MaterialApp(
          home: FinanceHomePage(
            viewModel: harness.viewModel,
            navCallbacks: FinanceNavCallbacks(
              onOpenDashboard: () {},
              onOpenAccounts: () {},
              onOpenTransactions: () {},
              onOpenCategories: () {},
              onOpenDiagnostics: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      final drawer = find.byType(Drawer);
      expect(find.descendant(of: drawer, matching: find.text('Dashboard')),
          findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Accounts')),
          findsOneWidget);
      expect(
          find.descendant(of: drawer, matching: find.text('Transactions')),
          findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Categories')),
          findsOneWidget);
      expect(find.descendant(of: drawer, matching: find.text('Diagnostics')),
          findsOneWidget);
    });

    testWidgets('tapping Accounts in the drawer invokes onOpenAccounts',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: FinanceHomePage(
            viewModel: harness.viewModel,
            navCallbacks: FinanceNavCallbacks(
              onOpenAccounts: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Drawer), matching: find.text('Accounts')),
      );
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('FinanceHomePage — refresh', () {
    testWidgets('pull-to-refresh reloads the dashboard', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1', name: 'Original')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('Original'), findsOneWidget);

      harness.accountRepo.seed([_account('acc-2', name: 'Newly Added')]);
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
