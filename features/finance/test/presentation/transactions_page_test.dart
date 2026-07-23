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
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/presentation/pages/transactions_page.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

// Mirrors accounts_page_test.dart: real use cases backed by Sprint 8A fake
// repositories (use case classes are `final class`, cannot be mocked).

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

final class _Harness {
  _Harness()
      : accountRepo = FakeAccountRepository(),
        txnRepo = FakeTransactionRepository() {
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
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeAccountRepository accountRepo;
  final FakeTransactionRepository txnRepo;
  late final TransactionsViewModel viewModel;

  Widget buildPage() =>
      MaterialApp(home: TransactionsPage(viewModel: viewModel));
}

void main() {
  group('TransactionsPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no transactions exist',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No transactions yet'), findsOneWidget);
    });

    testWidgets('shows a transaction after loading', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.textContaining('100'), findsWidgets);
    });
  });

  group('TransactionsPage — create', () {
    testWidgets('tapping the FAB opens the add-transaction dialog',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Transaction')),
        findsOneWidget,
      );
    });

    testWidgets('shows a message when no accounts exist yet', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Create an account first.'), findsOneWidget);
    });

    testWidgets('creating an expense adds it to the visible list',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '75');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.textContaining('75'), findsWidgets);
    });

    testWidgets('creating a transfer produces two list entries',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-from'), _account('acc-to')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Select the "Transfer" segment (defaults to "Expense").
      await tester.tap(find.text('Transfer'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Amount'), '200');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(harness.viewModel.state.dataOrNull, hasLength(2));
    });
  });

  group('TransactionsPage — edit', () {
    testWidgets('tapping a transaction opens the edit dialog', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
        note: 'Original note',
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original note'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Transaction'), findsOneWidget);
    });

    testWidgets('editing the note updates the list', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
        note: 'Original note',
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original note'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Note'),
        'Updated note',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Updated note'), findsOneWidget);
      expect(find.text('Original note'), findsNothing);
    });
  });

  // Drags the (sole) Dismissible and pumps in small increments until the
  // Undo SnackBar appears, instead of one fixed-duration pump. The
  // Dismissible's move+resize animation completion time is close to the
  // boundary of a single guessed duration and was observed to be flaky
  // (~500-700ms, varying by run); polling in 100ms steps up to 2s is
  // deterministic and stays well under the SnackBar's own ~4s auto-dismiss
  // timer, so it never accidentally settles that too.
  Future<void> dragAndWaitForSnackBar(WidgetTester tester) async {
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.text('Transaction deleted').evaluate().isNotEmpty) break;
    }
    // The SnackBar's own entrance (slide-in) animation is still mid-flight
    // right when its text first appears in the tree — its hit-testable
    // position keeps moving for a bit longer. Give it a bit more bounded
    // time to finish sliding in before any test taps on it (e.g. UNDO).
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('TransactionsPage — delete (swipe + Undo SnackBar)', () {
    // Milestone 4 migration replaced the delete-icon + confirmation-dialog
    // flow with swipe-to-delete (VPS §5.3.4). Milestone 5 Part A then
    // replaced *immediate* deletion with the Material 3 Undo pattern: the
    // row disappears immediately and a "Transaction deleted" SnackBar with
    // an UNDO action appears; the real
    // TransactionsViewModel.deleteTransaction call only fires once the
    // SnackBar closes without UNDO being tapped.

    testWidgets('swiping a transaction hides it and shows the Undo SnackBar '
        'without deleting it yet', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      // Bounded pumps only — pumpAndSettle would run the SnackBar's own
      // auto-dismiss timer to completion before returning, which is exactly
      // the behavior these tests need to observe mid-flight.
      await dragAndWaitForSnackBar(tester);

      expect(find.text('Transaction deleted'), findsOneWidget);
      expect(find.text('UNDO'), findsOneWidget);
      // Not yet actually deleted — the ViewModel's own data still has it.
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });

    testWidgets('tapping UNDO restores the transaction and never deletes it',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await dragAndWaitForSnackBar(tester);
      expect(find.text('No transactions yet'), findsNothing);
      // The row itself is hidden (a Dismissible commits its own removal),
      // but the underlying data is untouched.
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      await tester.tap(find.text('UNDO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(harness.viewModel.state.dataOrNull, hasLength(1));
      expect(find.textContaining('100'), findsWidgets);

      // Waiting out the SnackBar's duration afterwards must not finalize a
      // delete that was already undone.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(harness.viewModel.state.dataOrNull, hasLength(1));
    });

    testWidgets(
        'letting the SnackBar time out without tapping UNDO finalizes the '
        'deletion', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('100'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await dragAndWaitForSnackBar(tester);
      expect(harness.viewModel.state.dataOrNull, hasLength(1));

      // The SnackBar's real ~4s auto-dismiss Timer does not reliably fire
      // under flutter_test's fake clock even after many simulated seconds
      // of pumping, so the timeout is triggered directly here — this drives
      // the exact same `.closed` completion (with a non-`.action` reason)
      // that a real timeout produces, exercising the same finalization path.
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first))
          .hideCurrentSnackBar(reason: SnackBarClosedReason.timeout);
      await tester.pumpAndSettle();

      expect(harness.viewModel.state.dataOrNull, hasLength(0));
      expect(find.text('No transactions yet'), findsOneWidget);
    });
  });

  group('TransactionsPage — filtering', () {
    testWidgets('the transfers-only filter chip toggles the list',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-a'), _account('acc-b')]);
      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-a'),
        amount: Money(amount: Decimal.parse('10'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await harness.viewModel.createTransfer(
        fromAccountId: const AccountId('acc-a'),
        toAccountId: const AccountId('acc-b'),
        amount: Money(amount: Decimal.parse('50'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Transfers only'));
      await tester.pumpAndSettle();

      expect(harness.viewModel.transfersOnly, isTrue);
      expect(harness.viewModel.state.dataOrNull, hasLength(2));
    });
  });

  group('TransactionsPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No transactions yet'), findsOneWidget);

      await harness.viewModel.addExpense(
        accountId: const AccountId('acc-1'),
        amount: Money(amount: Decimal.parse('42'), currency: _inr),
        date: TransactionDate(DateTime(2024, 6, 15)),
      );
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.textContaining('42'), findsWidgets);
    });
  });
}
