import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/create_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/delete_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/update_account_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/services/balance_calculation_service.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_created_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_deleted_specification.dart';
import 'package:feature_finance/src/domain/specifications/account_can_be_updated_specification.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_change_signal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

// This suite exercises AccountsViewModel against *real* use cases (all
// `final class`, so they cannot be mocked/subclassed from a test file) backed
// by the existing Sprint 8A fake repositories. This proves the ViewModel's
// true orchestration behavior — including business rules the use cases
// enforce (e.g. deletion guards) — without duplicating repository-level
// tests, which already exist elsewhere.

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'acc-${++_i}';
}

const _ws = 'ws-1';
final _inr = CurrencyCode('INR');

Account _account(String id, {String name = 'Account', bool isActive = true}) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: name,
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.parse('1000'), currency: _inr),
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _expense(String id, String accountId, String amount) {
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse(amount), currency: _inr),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late WorkspaceContext workspaceContext;
  late AccountsViewModel viewModel;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);

    viewModel = AccountsViewModel(
      getAccountsUseCase: GetAccountsUseCase(accountRepository: accountRepo),
      createAccountUseCase: CreateAccountUseCase(
        accountRepository: accountRepo,
        idGenerator: _SequentialId(),
        specification: AccountCanBeCreatedSpecification(
          accountRepository: accountRepo,
        ),
      ),
      updateAccountUseCase: UpdateAccountUseCase(
        accountRepository: accountRepo,
        specification: AccountCanBeUpdatedSpecification(
          accountRepository: accountRepo,
        ),
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
      financeChangeSignal: FinanceChangeSignal(),
    );
  });

  group('AccountsViewModel.load — states', () {
    test('state is loading immediately after load() is called', () {
      final future = viewModel.load();
      expect(viewModel.state.isLoading, isTrue);
      return future;
    });

    test('state becomes success with an empty list when no accounts exist',
        () async {
      await viewModel.load();
      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });

    test('state becomes success with items when accounts exist', () async {
      accountRepo.seed([_account('acc-1', name: 'Savings')]);

      await viewModel.load();

      expect(viewModel.state.isSuccess, isTrue);
      final items = viewModel.state.dataOrNull!;
      expect(items, hasLength(1));
      expect(items.first.account.name, 'Savings');
    });

    test('each item carries the computed balance from GetAccountBalanceUseCase',
        () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_expense('t1', 'acc-1', '200')]);

      await viewModel.load();

      final item = viewModel.state.dataOrNull!.single;
      // initialBalance 1000 - expense 200 = 800
      expect(item.balance.amount, Decimal.parse('800'));
    });

    test('includes inactive accounts (Finance Stabilization: the Accounts '
        'list must show a deactivated account so it can be reactivated, '
        'unlike GetAccountsUseCase\'s default active-only behavior used '
        'elsewhere)', () async {
      accountRepo.seed([
        _account('acc-active', isActive: true),
        _account('acc-inactive', isActive: false),
      ]);

      await viewModel.load();

      expect(viewModel.state.dataOrNull, hasLength(2));
      expect(
        viewModel.state.dataOrNull!.map((item) => item.account.id),
        containsAll([const AccountId('acc-active'), const AccountId('acc-inactive')]),
      );
    });

    test('notifies listeners on each state transition', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.load();

      expect(notifyCount, greaterThanOrEqualTo(2)); // loading, then success
    });
  });

  group('AccountsViewModel.refresh', () {
    test('sets isRefreshing while keeping existing state visible', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();
      expect(viewModel.state.isSuccess, isTrue);

      final refreshFuture = viewModel.refresh();
      expect(viewModel.isRefreshing, isTrue);
      // Existing success state remains visible during refresh, not reset to
      // loading.
      expect(viewModel.state.isSuccess, isTrue);

      await refreshFuture;
      expect(viewModel.isRefreshing, isFalse);
    });

    test('refresh reflects newly seeded data', () async {
      await viewModel.load();
      expect(viewModel.state.dataOrNull, isEmpty);

      accountRepo.seed([_account('acc-1')]);
      await viewModel.refresh();

      expect(viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('AccountsViewModel — WorkspaceContext integration', () {
    test('workspaceId is always read live from WorkspaceContext, never cached',
        () {
      expect(viewModel.workspaceId, _ws);
      workspaceContext.switchTo('ws-2');
      expect(viewModel.workspaceId, 'ws-2');
    });

    test('switching the active workspace triggers an automatic reload',
        () async {
      accountRepo.seed([_account('acc-1', name: 'Workspace 1 Account')]);
      await viewModel.load();
      expect(viewModel.state.dataOrNull, hasLength(1));

      // Switching workspaces: the fake repository is not itself
      // workspace-scoped, but the reload is what this test verifies —
      // notifyListeners() firing in response to WorkspaceContext.switchTo.
      var notified = false;
      viewModel.addListener(() => notified = true);

      workspaceContext.switchTo('ws-2');
      await Future<void>.delayed(Duration.zero); // let the reload complete

      expect(notified, isTrue);
    });

    test('no longer reloads after the ViewModel is disposed', () async {
      viewModel.dispose();

      // Should not throw — the ViewModel unsubscribed from WorkspaceContext
      // in dispose(), so this switch must not touch a disposed ChangeNotifier.
      expect(() => workspaceContext.switchTo('ws-3'), returnsNormally);
    });
  });

  group('AccountsViewModel.createAccount', () {
    test('creates an account and reloads the list on success', () async {
      final result = await viewModel.createAccount(
        name: 'New Account',
        type: AccountType.cash,
        currency: _inr,
        initialBalance: Money(amount: Decimal.zero, currency: _inr),
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, hasLength(1));
      expect(viewModel.state.dataOrNull!.first.account.name, 'New Account');
    });

    test('returns a failure Result without reloading when creation is invalid',
        () async {
      // Negative initial balance for a non-credit-card account violates
      // Business Invariant 8 — CreateAccountUseCase rejects it.
      final result = await viewModel.createAccount(
        name: 'Bad Account',
        type: AccountType.savings,
        currency: _inr,
        initialBalance: Money(amount: Decimal.parse('-50'), currency: _inr),
      );

      expect(result.isFailure, isTrue);
      expect(accountRepo.store, isEmpty);
    });
  });

  group('AccountsViewModel.updateAccount', () {
    test('updates the account name and reloads the list', () async {
      accountRepo.seed([_account('acc-1', name: 'Old Name')]);
      await viewModel.load();

      final result = await viewModel.updateAccount(
        accountId: const AccountId('acc-1'),
        name: 'New Name',
      );

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull!.first.account.name, 'New Name');
    });

    test('returns a failure Result when the account does not exist', () async {
      final result = await viewModel.updateAccount(
        accountId: const AccountId('missing'),
        name: 'New Name',
      );
      expect(result.isFailure, isTrue);
    });
  });

  group('AccountsViewModel.deleteAccount', () {
    test('soft-deletes the account and reloads the list', () async {
      accountRepo.seed([_account('acc-1')]);
      await viewModel.load();

      final result = await viewModel.deleteAccount(const AccountId('acc-1'));

      expect(result.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });

    test('surfaces the specification failure message without deleting when '
        'the account has active transactions', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_expense('t1', 'acc-1', '100')]);
      await viewModel.load();

      final result = await viewModel.deleteAccount(const AccountId('acc-1'));

      expect(result.isFailure, isTrue);
      expect(
        result.exceptionOrNull!.message,
        contains('active transactions'),
      );
      // The account was not removed — the ViewModel did not bypass the rule.
      expect(accountRepo.store, hasLength(1));
    });
  });
}
