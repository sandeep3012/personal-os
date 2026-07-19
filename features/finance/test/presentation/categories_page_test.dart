import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_category_summary_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/services/category_summary_service.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:feature_finance/src/presentation/pages/categories_page.dart';
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_account_repository.dart';
import '../helpers/fake_transaction_repository.dart';

const _ws = 'ws-1';
final _inr = CurrencyCode('INR');

Account _account(String id) {
  final now = DateTime(2024, 1, 1);
  return Account(
    id: AccountId(id),
    workspaceId: _ws,
    name: 'Account',
    type: AccountType.savings,
    currency: _inr,
    initialBalance: Money(amount: Decimal.zero, currency: _inr),
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

Transaction _expense(String id, String accountId, String amount, {String? category}) {
  final now = DateTime.now();
  return Transaction(
    id: TransactionId(id),
    workspaceId: _ws,
    accountId: AccountId(accountId),
    type: TransactionType.expense,
    amount: Money(amount: Decimal.parse(amount), currency: _inr),
    categoryId: category == null ? null : CategoryId(category),
    date: TransactionDate(now),
    createdAt: now,
    updatedAt: now,
  );
}

final class _Harness {
  _Harness()
      : accountRepo = FakeAccountRepository(),
        txnRepo = FakeTransactionRepository() {
    viewModel = CategoriesViewModel(
      getCategorySummaryUseCase: GetCategorySummaryUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
        categorySummaryService: const CategorySummaryService(),
      ),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeAccountRepository accountRepo;
  final FakeTransactionRepository txnRepo;
  late final CategoriesViewModel viewModel;

  Widget buildPage() => MaterialApp(home: CategoriesPage(viewModel: viewModel));
}

void main() {
  group('CategoriesPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when there is no categorized spending',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No categorized spending yet'), findsOneWidget);
    });

    testWidgets('shows category items after loading', (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1')])
        ..txnRepo.seed([
          _expense('t1', 'acc-1', '200', category: 'cat-food'),
        ]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('cat-food'), findsOneWidget);
    });
  });

  group('CategoriesPage — search/filter', () {
    testWidgets('typing in the search field filters the visible list',
        (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1')])
        ..txnRepo.seed([
          _expense('t1', 'acc-1', '200', category: 'cat-food'),
          _expense('t2', 'acc-1', '300', category: 'cat-travel'),
        ]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('cat-food'), findsOneWidget);
      expect(find.text('cat-travel'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'food');
      await tester.pumpAndSettle();

      expect(find.text('cat-food'), findsOneWidget);
      expect(find.text('cat-travel'), findsNothing);
    });
  });

  group('CategoriesPage — no CRUD UI', () {
    testWidgets('no FloatingActionButton is present (categories are read-only)',
        (tester) async {
      final harness = _Harness()..accountRepo.seed([_account('acc-1')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('CategoriesPage — refresh', () {
    testWidgets('pull-to-refresh reloads category summaries', (tester) async {
      final harness = _Harness()
        ..accountRepo.seed([_account('acc-1')])
        ..txnRepo.seed([_expense('t1', 'acc-1', '200', category: 'cat-food')]);
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('cat-food'), findsOneWidget);

      harness.txnRepo.seed([
        _expense('t1', 'acc-1', '200', category: 'cat-food'),
        _expense('t2', 'acc-1', '100', category: 'cat-travel'),
      ]);
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('cat-travel'), findsOneWidget);
    });
  });
}
