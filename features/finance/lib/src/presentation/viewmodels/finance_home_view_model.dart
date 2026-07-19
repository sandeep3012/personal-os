import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_net_position_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_expenses_use_case.dart';
import 'package:feature_finance/src/application/use_cases/summary/get_total_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/finance_period.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:flutter/foundation.dart';

/// The Finance Dashboard's aggregated view data — a presentation-layer
/// combination of several use-case results. Not a domain type.
final class FinanceDashboardData {
  const FinanceDashboardData({
    required this.accounts,
    required this.totalBalanceByCurrency,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netPosition,
    required this.recentTransactions,
  });

  /// Every active account with its computed balance (same shape
  /// [AccountsViewModel] uses).
  final List<AccountListItem> accounts;

  /// Net worth, grouped by currency code. DOC-031 §9 R7 explicitly defers
  /// cross-currency conversion — summing balances across different
  /// currencies into a single number would be architecturally wrong, so
  /// this is a per-currency breakdown, not one total.
  final Map<String, Money> totalBalanceByCurrency;

  /// Total income for the current calendar month, in the dashboard's
  /// reporting currency (see [FinanceHomeViewModel] for how that currency
  /// is chosen).
  final Money totalIncome;

  /// Total expenses for the current calendar month, same reporting
  /// currency as [totalIncome].
  final Money totalExpenses;

  /// Net position (income − expenses) for the current calendar month, same
  /// reporting currency as [totalIncome]/[totalExpenses]. Positive means the
  /// workspace earned more than it spent this month.
  final Money netPosition;

  /// The five most recent transactions across all accounts.
  final List<Transaction> recentTransactions;
}

/// Drives [FinanceHomePage]: the Finance feature's landing page, showing a
/// concise overview (balances, income/expense summary, recent activity).
///
/// Depends only on use cases — never on a repository, DAO, or specification
/// directly, mirroring [AccountsViewModel]/[TransactionsViewModel] exactly
/// (ADR-004). Orchestrates five use cases without duplicating any business
/// logic each already performs.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004).
final class FinanceHomeViewModel extends ChangeNotifier {
  FinanceHomeViewModel({
    required GetAccountsUseCase getAccountsUseCase,
    required GetAccountBalanceUseCase getAccountBalanceUseCase,
    required GetTotalIncomeUseCase getTotalIncomeUseCase,
    required GetTotalExpensesUseCase getTotalExpensesUseCase,
    required GetNetPositionUseCase getNetPositionUseCase,
    required QueryTransactionsUseCase queryTransactionsUseCase,
    required WorkspaceContext workspaceContext,
  })  : _getAccountsUseCase = getAccountsUseCase,
        _getAccountBalanceUseCase = getAccountBalanceUseCase,
        _getTotalIncomeUseCase = getTotalIncomeUseCase,
        _getTotalExpensesUseCase = getTotalExpensesUseCase,
        _getNetPositionUseCase = getNetPositionUseCase,
        _queryTransactionsUseCase = queryTransactionsUseCase,
        _workspaceContext = workspaceContext {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetAccountsUseCase _getAccountsUseCase;
  final GetAccountBalanceUseCase _getAccountBalanceUseCase;
  final GetTotalIncomeUseCase _getTotalIncomeUseCase;
  final GetTotalExpensesUseCase _getTotalExpensesUseCase;
  final GetNetPositionUseCase _getNetPositionUseCase;
  final QueryTransactionsUseCase _queryTransactionsUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<FinanceDashboardData> _state = const AsyncState.loading();

  /// The current load state: loading, success (with dashboard data), or
  /// error.
  AsyncState<FinanceDashboardData> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing dashboard while new data loads.
  bool get isRefreshing => _isRefreshing;

  /// Loads the dashboard for the first time (or after an error), showing
  /// the full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads while keeping the current dashboard visible ([isRefreshing]
  /// becomes `true` instead of resetting [state] to loading).
  Future<void> refresh() => _fetch(isRefresh: true);

  Future<void> _fetch({required bool isRefresh}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _state = const AsyncState.loading();
    }
    notifyListeners();

    final accountsResult = await _getAccountsUseCase.execute(
      GetAccountsInput(workspaceId: workspaceId),
    );
    if (accountsResult.isFailure) {
      _state = AsyncState.error(accountsResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }
    final rawAccounts = accountsResult.valueOrNull!;

    final balanceResults = await Future.wait(
      rawAccounts.map(
        (a) => _getAccountBalanceUseCase.execute(
          GetAccountBalanceInput(accountId: a.id, workspaceId: workspaceId),
        ),
      ),
    );

    final accountItems = [
      for (var i = 0; i < rawAccounts.length; i++)
        AccountListItem(
          account: rawAccounts[i],
          balance: balanceResults[i].valueOrNull ??
              Money(amount: Decimal.zero, currency: rawAccounts[i].currency),
        ),
    ];

    final totalBalanceByCurrency = <String, Money>{};
    for (final item in accountItems) {
      final code = item.balance.currency.value;
      final existing = totalBalanceByCurrency[code];
      totalBalanceByCurrency[code] = existing == null
          ? item.balance
          : Money(
              amount: existing.amount + item.balance.amount,
              currency: item.balance.currency,
            );
    }

    // Reporting currency for period summaries: the first account's
    // currency, or INR if there are no accounts yet. DOC-031 §9 R7 defers
    // true multi-currency reporting; GetTotalIncomeUseCase/
    // GetTotalExpensesUseCase already require one reporting currency
    // parameter today, unchanged by this step.
    final reportingCurrency = rawAccounts.isEmpty
        ? CurrencyCode('INR')
        : rawAccounts.first.currency;
    final period = FinancePeriod.fromDateTime(DateTime.now());

    final incomeResult = await _getTotalIncomeUseCase.execute(GetTotalIncomeInput(
      workspaceId: workspaceId,
      period: period,
      currency: reportingCurrency,
    ));
    final expensesResult =
        await _getTotalExpensesUseCase.execute(GetTotalExpensesInput(
      workspaceId: workspaceId,
      period: period,
      currency: reportingCurrency,
    ));

    if (incomeResult.isFailure) {
      _state = AsyncState.error(incomeResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }
    if (expensesResult.isFailure) {
      _state = AsyncState.error(expensesResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final netPositionResult = await _getNetPositionUseCase.execute(
      GetNetPositionInput(
        workspaceId: workspaceId,
        period: period,
        currency: reportingCurrency,
      ),
    );
    if (netPositionResult.isFailure) {
      _state = AsyncState.error(netPositionResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final recentResult = await _queryTransactionsUseCase.execute(
      TransactionQuery(workspaceId: workspaceId, pageSize: 5),
    );
    final recentTransactions =
        recentResult.isSuccess ? recentResult.valueOrNull!.items : const <Transaction>[];

    _state = AsyncState.success(FinanceDashboardData(
      accounts: accountItems,
      totalBalanceByCurrency: totalBalanceByCurrency,
      totalIncome: incomeResult.valueOrNull!,
      totalExpenses: expensesResult.valueOrNull!,
      netPosition: netPositionResult.valueOrNull!,
      recentTransactions: recentTransactions,
    ));
    _isRefreshing = false;
    notifyListeners();
  }
}
