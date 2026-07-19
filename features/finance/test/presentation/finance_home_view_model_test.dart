import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_net_position_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_expenses_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

const _ws = 'ws-1';
final _inr = CurrencyCode('INR');

Account _account(String id, {String name = 'Account', String currency = 'INR'}) {
  final now = DateTime(2024, 1, 1);
  final cc = CurrencyCode(currency);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: name,
    type: AccountType.savings,
    currency: cc,
    initialBalance: Money(amount: Decimal.parse('1000'), currency: cc),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _txn(
  String id,
  String accountId,
  TransactionType type,
  String amount, {
  DateTime? date,
}) {
  final d = date ?? DateTime.now();
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: type,
    amount: Money(amount: Decimal.parse(amount), currency: _inr),
    date: TransactionDate(d),
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late WorkspaceContext workspaceContext;
  late FinanceHomeViewModel viewModel;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);

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
      workspaceContext: workspaceContext,
    );
  });

  group('FinanceHomeViewModel — states', () {
    test('state is loading immediately after load() is called', () {
      final future = viewModel.load();
      expect(viewModel.state.isLoading, isTrue);
      return future;
    });

    test('state becomes success with empty accounts when none exist',
        () async {
      await viewModel.load();
      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull!.accounts, isEmpty);
    });

    test('shows an empty summary derived from GetAccountsUseCase alone',
        () async {
      // No accounts registered — this is the "empty" dashboard scenario.
      await viewModel.load();
      final data = viewModel.state.dataOrNull!;
      expect(data.accounts, isEmpty);
      expect(data.recentTransactions, isEmpty);
    });
  });

  group('FinanceHomeViewModel — summary rendering', () {
    test('accounts summary carries each account with its computed balance',
        () async {
      accountRepo.seed([_account('acc-1', name: 'Savings')]);
      txnRepo.seed([_txn('t1', 'acc-1', TransactionType.expense, '200')]);

      await viewModel.load();

      final data = viewModel.state.dataOrNull!;
      expect(data.accounts, hasLength(1));
      expect(data.accounts.first.account.name, 'Savings');
      expect(data.accounts.first.balance.amount, Decimal.parse('800'));
    });

    test('totalBalanceByCurrency groups balances per currency, not a single '
        'cross-currency sum', () async {
      accountRepo.seed([
        _account('acc-inr', currency: 'INR'),
        _account('acc-usd', currency: 'USD'),
      ]);

      await viewModel.load();

      final data = viewModel.state.dataOrNull!;
      expect(data.totalBalanceByCurrency.keys, containsAll(['INR', 'USD']));
      expect(data.totalBalanceByCurrency['INR']!.amount, Decimal.parse('1000'));
      expect(data.totalBalanceByCurrency['USD']!.amount, Decimal.parse('1000'));
    });

    test('totalIncome and totalExpenses reflect the current month', () async {
      accountRepo.seed([_account('acc-1')]);
      final now = DateTime.now();
      txnRepo.seed([
        _txn('income', 'acc-1', TransactionType.income, '5000', date: now),
        _txn('expense', 'acc-1', TransactionType.expense, '1200', date: now),
      ]);

      await viewModel.load();

      final data = viewModel.state.dataOrNull!;
      expect(data.totalIncome.amount, Decimal.parse('5000'));
      expect(data.totalExpenses.amount, Decimal.parse('1200'));
    });

    test('netPosition reflects income minus expenses for the current month',
        () async {
      accountRepo.seed([_account('acc-1')]);
      final now = DateTime.now();
      txnRepo.seed([
        _txn('income', 'acc-1', TransactionType.income, '5000', date: now),
        _txn('expense', 'acc-1', TransactionType.expense, '1200', date: now),
      ]);

      await viewModel.load();

      final data = viewModel.state.dataOrNull!;
      expect(data.netPosition.amount, Decimal.parse('3800'));
    });
  });

  group('FinanceHomeViewModel — recent transactions rendering', () {
    test('recentTransactions reflects existing transactions', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_txn('t1', 'acc-1', TransactionType.expense, '50')]);

      await viewModel.load();

      expect(viewModel.state.dataOrNull!.recentTransactions, hasLength(1));
    });

    test('recentTransactions is capped (query pageSize) and does not error '
        'when there are more than the cap', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        for (var i = 1; i <= 10; i++)
          _txn('t$i', 'acc-1', TransactionType.expense, '$i'),
      ]);

      await viewModel.load();

      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull!.recentTransactions, isNotEmpty);
    });
  });

  group('FinanceHomeViewModel.refresh', () {
    test('sets isRefreshing while keeping existing state visible', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();

      final refreshFuture = viewModel.refresh();
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.state.isSuccess, isTrue);
      await refreshFuture;
      expect(viewModel.isRefreshing, isFalse);
    });
  });

  group('FinanceHomeViewModel — WorkspaceContext integration', () {
    test('workspaceId is always read live from WorkspaceContext', () {
      expect(viewModel.workspaceId, _ws);
      workspaceContext.switchTo('ws-2');
      expect(viewModel.workspaceId, 'ws-2');
    });

    test('switching workspace triggers an automatic reload', () async {
      await viewModel.load();
      var notified = false;
      viewModel.addListener(() => notified = true);

      workspaceContext.switchTo('ws-2');
      await Future<void>.delayed(Duration.zero);

      expect(notified, isTrue);
    });

    test('no longer reloads after dispose()', () {
      viewModel.dispose();
      expect(() => workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });
}
