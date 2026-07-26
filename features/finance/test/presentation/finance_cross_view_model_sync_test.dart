import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/create_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/delete_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/update_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_expense_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/create_transfer_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/delete_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/restore_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/update_transaction_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_change_signal.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

// This suite exists specifically to prove Finance Stabilization Part 2:
// AccountsViewModel and TransactionsViewModel are two independent
// ChangeNotifiers (each a DI factory — a fresh instance per page mount, per
// FinanceModule), so without FinanceChangeSignal there is no way for a
// mutation on one to reach the other. Every test below constructs BOTH
// ViewModels sharing the SAME FinanceChangeSignal instance (exactly as
// FinanceModule's DI wiring does via registerLazySingleton) and asserts
// AccountsViewModel's balance updates *without* AccountsViewModel.refresh()
// ever being called directly — only TransactionsViewModel's own mutation
// methods trigger it.

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'txn-${++_i}';
}

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

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late FinanceChangeSignal financeChangeSignal;
  late AccountsViewModel accountsViewModel;
  late TransactionsViewModel transactionsViewModel;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    financeChangeSignal = FinanceChangeSignal();
    final workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);

    accountsViewModel = AccountsViewModel(
      getAccountsUseCase: GetAccountsUseCase(accountRepository: accountRepo),
      createAccountUseCase: CreateAccountUseCase(
        accountRepository: accountRepo,
        idGenerator: _SequentialId(),
        specification: AccountCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      updateAccountUseCase: UpdateAccountUseCase(
        accountRepository: accountRepo,
        specification: AccountCanBeUpdatedSpecification(accountRepository: accountRepo),
      ),
      deleteAccountUseCase: DeleteAccountUseCase(
        accountRepository: accountRepo,
        specification: AccountCanBeDeletedSpecification(
          accountRepository: accountRepo,
          transactionRepository: txnRepo,
        ),
      ),
      getAccountBalanceUseCase: GetAccountBalanceUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
        balanceCalculationService: const BalanceCalculationService(),
      ),
      workspaceContext: workspaceContext,
      financeChangeSignal: financeChangeSignal,
    );

    transactionsViewModel = TransactionsViewModel(
      getAccountsUseCase: GetAccountsUseCase(accountRepository: accountRepo),
      queryTransactionsUseCase: QueryTransactionsUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      addExpenseUseCase: AddExpenseUseCase(
        transactionRepository: txnRepo,
        idGenerator: _SequentialId(),
        specification: TransactionCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      addIncomeUseCase: AddIncomeUseCase(
        transactionRepository: txnRepo,
        idGenerator: _SequentialId(),
        specification: TransactionCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      updateTransactionUseCase: UpdateTransactionUseCase(transactionRepository: txnRepo),
      deleteTransactionUseCase: DeleteTransactionUseCase(transactionRepository: txnRepo),
      restoreTransactionUseCase: RestoreTransactionUseCase(transactionRepository: txnRepo),
      createTransferUseCase: CreateTransferUseCase(
        transactionRepository: txnRepo,
        transferService: TransferService(idGenerator: _SequentialId()),
        specification: TransferCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      workspaceContext: workspaceContext,
      financeChangeSignal: financeChangeSignal,
    );
  });

  group('FinanceChangeSignal — AccountsViewModel reacts to TransactionsViewModel', () {
    test('account balance refreshes immediately after creating a transaction (expense)',
        () async {
      accountRepo.seed([_account('acc-1')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();
      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('1000'));

      await transactionsViewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('250'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 1)),
      );

      // No explicit accountsViewModel.refresh() call anywhere above —
      // only the shared FinanceChangeSignal makes this observable.
      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('750'));
    });

    test('account balance refreshes immediately after updating a transaction',
        () async {
      accountRepo.seed([_account('acc-1')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();
      final created = await transactionsViewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 1)),
      );
      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('900'));

      await transactionsViewModel.updateTransaction(
        transactionId: created.valueOrNull!.id,
        amount: Money(amount: Decimal.parse('400'), currency: _inr),
      );

      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('600'));
    });

    test('account balance refreshes immediately after deleting a transaction',
        () async {
      accountRepo.seed([_account('acc-1')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();
      final created = await transactionsViewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('300'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 1)),
      );
      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('700'));

      await transactionsViewModel.deleteTransaction(created.valueOrNull!.id);

      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('1000'));
    });

    test('account balance refreshes immediately after restoring a transaction',
        () async {
      accountRepo.seed([_account('acc-1')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();
      final created = await transactionsViewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('300'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 1)),
      );
      await transactionsViewModel.deleteTransaction(created.valueOrNull!.id);
      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('1000'));

      await transactionsViewModel.restoreTransaction(created.valueOrNull!.id);

      expect(accountsViewModel.state.dataOrNull!.single.balance.amount, Decimal.parse('700'));
    });

    test('both account balances refresh immediately after a transfer', () async {
      accountRepo.seed([_account('acc-1', name: 'From'), _account('acc-2', name: 'To')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();

      await transactionsViewModel.createTransfer(
        fromAccountId: const AccountId('acc-1'),
        toAccountId: const AccountId('acc-2'),
        amount: Money(amount: Decimal.parse('200'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 1)),
      );

      final items = accountsViewModel.state.dataOrNull!;
      final from = items.firstWhere((i) => i.account.id.value == 'acc-1');
      final to = items.firstWhere((i) => i.account.id.value == 'acc-2');
      expect(from.balance.amount, Decimal.parse('800'));
      expect(to.balance.amount, Decimal.parse('1200'));
    });

    test('disposing AccountsViewModel stops it from reacting further',
        () async {
      accountRepo.seed([_account('acc-1')]);
      await accountsViewModel.load();
      await transactionsViewModel.load();

      accountsViewModel.dispose();

      // Must not throw despite the listener having been removed.
      await expectLater(
        transactionsViewModel.addExpense(
          accountId: const AccountId('acc-1'),
          amount: Money(amount: Decimal.parse('50'), currency: _inr),
          date: TransactionDate(DateTime(2024, 6, 1)),
        ),
        completes,
      );
    });
  });
}
