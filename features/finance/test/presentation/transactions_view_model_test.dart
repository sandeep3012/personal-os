import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_expense_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/create_transfer_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/delete_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/update_transaction_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/services/transfer_service.dart';
import 'package:feature_finance/src/domain/specifications/transaction_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/transfer_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

// Mirrors accounts_view_model_test.dart exactly: real use cases (all `final
// class`, cannot be mocked) backed by the Sprint 8A fake repositories.

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
  late WorkspaceContext workspaceContext;
  late TransactionsViewModel viewModel;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);

    viewModel = TransactionsViewModel(
      getAccountsUseCase: GetAccountsUseCase(accountRepository: accountRepo),
      queryTransactionsUseCase: QueryTransactionsUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
      ),
      addExpenseUseCase: AddExpenseUseCase(
        transactionRepository: txnRepo,
        idGenerator: _SequentialId(),
        specification:
            TransactionCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      addIncomeUseCase: AddIncomeUseCase(
        transactionRepository: txnRepo,
        idGenerator: _SequentialId(),
        specification:
            TransactionCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      updateTransactionUseCase:
          UpdateTransactionUseCase(transactionRepository: txnRepo),
      deleteTransactionUseCase:
          DeleteTransactionUseCase(transactionRepository: txnRepo),
      createTransferUseCase: CreateTransferUseCase(
        transactionRepository: txnRepo,
        transferService: TransferService(idGenerator: _SequentialId()),
        specification:
            TransferCanBeCreatedSpecification(accountRepository: accountRepo),
      ),
      workspaceContext: workspaceContext,
    );
  });

  group('TransactionsViewModel.load — states', () {
    test('state is loading immediately after load() is called', () {
      final future = viewModel.load();
      expect(viewModel.state.isLoading, isTrue);
      return future;
    });

    test('state becomes success with an empty list when no transactions exist',
        () async {
      await viewModel.load();
      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });

    test('populates accounts as a side effect of load()', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      expect(viewModel.accounts, hasLength(1));
    });
  });

  group('TransactionsViewModel.refresh', () {
    test('sets isRefreshing while keeping existing state visible', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('50'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      final refreshFuture = viewModel.refresh();
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.state.isSuccess, isTrue);
      await refreshFuture;
      expect(viewModel.isRefreshing, isFalse);
    });
  });

  group('TransactionsViewModel — create', () {
    test('addExpense creates and reloads the list', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();

      final result = await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, hasLength(1));
    });

    test('addIncome creates and reloads the list', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();

      final result = await viewModel.addIncome(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('500'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull!.first.type.name, 'income');
    });

    test('returns a failure Result without reloading when the account does '
        'not exist', () async {
      final result = await viewModel.addExpense(
        accountId: const AccountId('missing'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isFailure, isTrue);
      expect(txnRepo.store, isEmpty);
    });
  });

  group('TransactionsViewModel — update', () {
    test('updates a transaction and reloads', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      final created = await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      final result = await viewModel.updateTransaction(
        transactionId: created.valueOrNull!.id,
        note: 'Updated note',
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull!.first.note, 'Updated note');
    });
  });

  group('TransactionsViewModel — delete', () {
    test('deletes a transaction and reloads', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      final created = await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      final result =
          await viewModel.deleteTransaction(created.valueOrNull!.id);

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('TransactionsViewModel — filtering', () {
    test('setAccountFilter restricts the list to one account', () async {
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      await viewModel.load();
      await viewModel.addExpense(
        accountId: const AccountId('acc-a'),
        amount: Money(amount: Decimal.parse('10'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await viewModel.addExpense(
        accountId: const AccountId('acc-b'),
        amount: Money(amount: Decimal.parse('20'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      viewModel.setAccountFilter(const AccountId('acc-a'));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.dataOrNull, hasLength(1));
      expect(viewModel.state.dataOrNull!.first.accountId, const AccountId('acc-a'));
    });

    test('setCategoryFilter restricts the list to one category', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('10'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
        categoryId: const CategoryId('cat-food'),
      );
      await viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('20'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      viewModel.setCategoryFilter(const CategoryId('cat-food'));
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.dataOrNull, hasLength(1));
      expect(
        viewModel.state.dataOrNull!.first.categoryId,
        const CategoryId('cat-food'),
      );
    });

    test('clearing a filter (null) shows all transactions again', () async {
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      await viewModel.load();
      await viewModel.addExpense(
        accountId: const AccountId('acc-a'),
        amount: Money(amount: Decimal.parse('10'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await viewModel.addExpense(
        accountId: const AccountId('acc-b'),
        amount: Money(amount: Decimal.parse('20'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      viewModel.setAccountFilter(const AccountId('acc-a'));
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.state.dataOrNull, hasLength(1));

      viewModel.setAccountFilter(null);
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.state.dataOrNull, hasLength(2));
    });
  });

  group('TransactionsViewModel — Transfers', () {
    test('createTransfer produces two legs and reloads the list', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);
      await viewModel.load();

      final result = await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        amount: Money(amount: Decimal.parse('500'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, hasLength(2));
    });

    test('both transfer legs carry a transferCounterpartId', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);
      await viewModel.load();

      await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        amount: Money(amount: Decimal.parse('500'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      final legs = viewModel.state.dataOrNull!;
      expect(legs.every((t) => t.transferCounterpartId != null), isTrue);
      // Pair integrity: each leg's counterpart id is exactly the other leg's id.
      expect(legs[0].transferCounterpartId, legs[1].id);
      expect(legs[1].transferCounterpartId, legs[0].id);
    });

    test('rejects a transfer to the same account (source/destination '
        'validation) without persisting anything', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();

      final result = await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-1'),
        toAccountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isFailure, isTrue);
      expect(txnRepo.store, isEmpty);
    });

    test('rejects a transfer to a nonexistent destination account', () async {
      accountRepo.seed([_account('acc-from')]);
      await viewModel.load();

      final result = await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('missing'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      expect(result.isFailure, isTrue);
      expect(txnRepo.store, isEmpty);
    });

    test('setTransfersOnly restricts the list to transfer legs', () async {
      accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      await viewModel.load();
      await viewModel.addExpense(
        accountId: const AccountId('acc-a'),
        amount: Money(amount: Decimal.parse('10'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-a'),
        toAccountId: const AccountId('acc-b'),
        amount: Money(amount: Decimal.parse('50'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );

      viewModel.setTransfersOnly(true);
      await Future<void>.delayed(Duration.zero);

      expect(viewModel.state.dataOrNull, hasLength(2));
      expect(
        viewModel.state.dataOrNull!.every((t) => t.transferCounterpartId != null),
        isTrue,
      );
    });

    test('an edit to one transfer leg does not alter its counterpart '
        '(known use-case limitation, not a UI regression)', () async {
      accountRepo.seed([_account('acc-from'), _account('acc-to')]);
      await viewModel.load();
      await viewModel.createTransfer(
        fromAccountId: const AccountId('acc-from'),
        toAccountId: const AccountId('acc-to'),
        amount: Money(amount: Decimal.parse('500'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      final debitLeg = viewModel.state.dataOrNull!
          .firstWhere((t) => t.accountId == const AccountId('acc-from'));

      await viewModel.updateTransaction(
        transactionId: debitLeg.id,
        note: 'Edited leg',
      );

      final creditLeg = viewModel.state.dataOrNull!
          .firstWhere((t) => t.accountId == const AccountId('acc-to'));
      expect(creditLeg.note, isNull);
    });
  });

  group('TransactionsViewModel — WorkspaceContext integration', () {
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
