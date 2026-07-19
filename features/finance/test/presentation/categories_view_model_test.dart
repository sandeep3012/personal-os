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
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
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

void main() {
  late FakeAccountRepository accountRepo;
  late FakeTransactionRepository txnRepo;
  late WorkspaceContext workspaceContext;
  late CategoriesViewModel viewModel;

  setUp(() {
    accountRepo = FakeAccountRepository();
    txnRepo = FakeTransactionRepository();
    workspaceContext = WorkspaceContext(initialWorkspaceId: _ws);

    viewModel = CategoriesViewModel(
      getCategorySummaryUseCase: GetCategorySummaryUseCase(
        accountRepository: accountRepo,
        transactionRepository: txnRepo,
        categorySummaryService: const CategorySummaryService(),
      ),
      workspaceContext: workspaceContext,
    );
  });

  group('CategoriesViewModel — states', () {
    test('state is loading immediately after load() is called', () {
      final future = viewModel.load();
      expect(viewModel.state.isLoading, isTrue);
      return future;
    });

    test('state becomes success with an empty list when no categorized '
        'expenses exist', () async {
      await viewModel.load();
      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });

    test('state becomes success with items when categorized expenses exist',
        () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', 'acc-1', '200', category: 'cat-food'),
        _expense('t2', 'acc-1', '150', category: 'cat-food'),
        _expense('t3', 'acc-1', '800', category: 'cat-travel'),
      ]);

      await viewModel.load();

      final items = viewModel.state.dataOrNull!;
      expect(items, hasLength(2));
      final food = items.firstWhere((i) => i.categoryId.value == 'cat-food');
      expect(food.total.amount, Decimal.parse('350'));
    });

    test('excludes uncategorized expenses', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', 'acc-1', '100', category: 'cat-food'),
        _expense('t2', 'acc-1', '50'),
      ]);

      await viewModel.load();

      expect(viewModel.state.dataOrNull, hasLength(1));
    });
  });

  group('CategoriesViewModel.refresh', () {
    test('sets isRefreshing while keeping existing state visible', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_expense('t1', 'acc-1', '100', category: 'cat-food')]);
      await viewModel.load();

      final refreshFuture = viewModel.refresh();
      expect(viewModel.isRefreshing, isTrue);
      expect(viewModel.state.isSuccess, isTrue);
      await refreshFuture;
      expect(viewModel.isRefreshing, isFalse);
    });
  });

  group('CategoriesViewModel — search/filter', () {
    test('setSearchQuery filters the list client-side without re-fetching',
        () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', 'acc-1', '100', category: 'cat-food'),
        _expense('t2', 'acc-1', '200', category: 'cat-travel'),
      ]);
      await viewModel.load();
      expect(viewModel.state.dataOrNull, hasLength(2));

      viewModel.setSearchQuery('food');

      expect(viewModel.state.dataOrNull, hasLength(1));
      expect(viewModel.state.dataOrNull!.first.categoryId.value, 'cat-food');
    });

    test('search is case-insensitive', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_expense('t1', 'acc-1', '100', category: 'cat-Food')]);
      await viewModel.load();

      viewModel.setSearchQuery('FOOD');

      expect(viewModel.state.dataOrNull, hasLength(1));
    });

    test('clearing the search query restores the full list', () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([
        _expense('t1', 'acc-1', '100', category: 'cat-food'),
        _expense('t2', 'acc-1', '200', category: 'cat-travel'),
      ]);
      await viewModel.load();

      viewModel.setSearchQuery('food');
      expect(viewModel.state.dataOrNull, hasLength(1));

      viewModel.setSearchQuery('');
      expect(viewModel.state.dataOrNull, hasLength(2));
    });

    test('a query matching nothing yields an empty (not error) state',
        () async {
      accountRepo.seed([_account('acc-1')]);
      txnRepo.seed([_expense('t1', 'acc-1', '100', category: 'cat-food')]);
      await viewModel.load();

      viewModel.setSearchQuery('nonexistent');

      expect(viewModel.state.isSuccess, isTrue);
      expect(viewModel.state.dataOrNull, isEmpty);
    });

    test('search does not affect the loading/error state passthrough', () {
      // Loading state before any load() call — searchQuery must not alter it.
      viewModel.setSearchQuery('anything');
      expect(viewModel.state.isLoading, isTrue);
    });
  });

  group('CategoriesViewModel — WorkspaceContext integration', () {
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
