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
import 'package:feature_finance/src/presentation/pages/accounts_page.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_change_signal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

// Widget tests for AccountsPage, driven by a real AccountsViewModel wired to
// the Sprint 8A fake repositories (same rationale as
// accounts_view_model_test.dart — use cases are `final class` and cannot be
// mocked). These tests exercise UI state rendering and user interaction
// wiring only; repository/use-case correctness is covered elsewhere.

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'acc-${++_i}';
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
    initialBalance: Money(amount: Decimal.parse('500'), currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _expense(String id, String accountId) {
  final now = DateTime(2024, 6, 15);
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse('50'), currency: _inr),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness()
      : accountRepo = FakeAccountRepository(),
        txnRepo = FakeTransactionRepository() {
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
        specification:
            AccountCanBeUpdatedSpecification(accountRepository: accountRepo),
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
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
      financeChangeSignal: FinanceChangeSignal(),
    );
  }

  final FakeAccountRepository accountRepo;
  final FakeTransactionRepository txnRepo;
  late final AccountsViewModel viewModel;

  Widget buildPage() =>
      MaterialApp(home: AccountsPage(viewModel: viewModel));
}

void main() {
  group('AccountsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no accounts exist',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('shows account names and balances after loading',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1', name: 'Savings')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Savings'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('reflects a computed balance that accounts for transactions',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1')])
        ..txnRepo.seed([_expense('t1', 'acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      // 500 initial - 50 expense = 450
      expect(find.textContaining('450'), findsOneWidget);
    });

    // No widget test exercises the error view: FakeAccountRepository never
    // fails, so there's no deterministic way to drive AccountsPage into its
    // error branch without a throwing test double for a repository — and
    // the error branch itself (AsyncState.error → _ErrorView with a retry
    // button) is a single unconditional render path already covered by
    // AccountsViewModel's own state transitions in
    // accounts_view_model_test.dart. Introducing a throwing fake here would
    // duplicate that coverage rather than add to it.
  });

  group('AccountsPage — create', () {
    testWidgets('tapping the FAB opens a create dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('creating an account adds it to the visible list',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Wallet');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Wallet'), findsOneWidget);
    });
  });

  group('AccountsPage — edit', () {
    testWidgets('tapping an account opens an edit dialog pre-filled with its '
        'name', (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1', name: 'Original')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Account'), findsOneWidget);
      expect(find.text('Original'), findsWidgets); // list tile + text field
    });

    testWidgets('editing the name updates the list', (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1', name: 'Original')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });

    testWidgets('toggling the Active switch off deactivates the account and '
        'it stays visible, labeled Inactive', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1', name: 'Toggle Me')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Toggle Me'));
      await tester.pumpAndSettle();

      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.tap(find.byType(SwitchListTile));
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      // Still visible (not silently hidden), now labeled Inactive.
      expect(find.text('Toggle Me'), findsOneWidget);
      expect(find.textContaining('Inactive'), findsOneWidget);
    });

    testWidgets('the Active switch does not appear on the Create Account form',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNothing);
    });
  });

  // Swipe-to-delete (Finance Stabilization accessibility pass) replaced the
  // previous undiscoverable long-press affordance — mirrors
  // TransactionsPage's already-established swipe pattern.
  Future<void> dragAccountTile(WidgetTester tester, String name) async {
    final dismissible = find.ancestor(
      of: find.text(name),
      matching: find.byType(Dismissible),
    );
    await tester.drag(dismissible, const Offset(-500, 0));
    await tester.pumpAndSettle();
  }

  group('AccountsPage — delete', () {
    testWidgets('deleting an account with no transactions removes it',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await dragAccountTile(tester, 'Account');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('deleting an account with active transactions shows the '
        'specification failure message, not a UI-level duplicate rule',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1', name: 'Has Transactions')])
        ..txnRepo.seed([_expense('t1', 'acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await dragAccountTile(tester, 'Has Transactions');
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      // The account remains in the list — deletion was rejected, so the
      // Dismissible snaps back into place.
      expect(find.text('Has Transactions'), findsOneWidget);
      // The failure message (from AccountCanBeDeletedSpecification, surfaced
      // via DeleteAccountUseCase) appears in a SnackBar.
      expect(find.textContaining('active transactions'), findsOneWidget);
    });

    testWidgets('cancelling the delete confirmation keeps the account',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await dragAccountTile(tester, 'Account');
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Account'), findsOneWidget);
    });
  });

  group('AccountsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No accounts yet'), findsOneWidget);

      harness.accountRepo.seed([_account('acc-1', name: 'Newly Added')]);
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
