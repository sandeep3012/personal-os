import 'package:application/application.dart';
import 'package:decimal/decimal.dart';
import 'package:feature_finance/src/application/use_cases/account/create_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/delete_account_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_account_balance_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/account/update_account_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_change_signal.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// An [Account] paired with its computed current balance, for display only.
///
/// Not a domain type — a presentation-layer combination of two use-case
/// results.
final class AccountListItem {
  const AccountListItem({required this.account, required this.balance});

  final Account account;
  final Money balance;
}

/// Drives [AccountsPage]: loads accounts with their balances, and exposes
/// create/update/delete operations.
///
/// Depends only on use cases — never on a repository, DAO, or specification
/// directly. All business rules (name validation, deletion guards, currency
/// matching, etc.) are enforced by the use cases and the domain/specification
/// layers beneath them; this ViewModel neither duplicates nor bypasses them —
/// it only orchestrates calls and surfaces whatever [Result] they return.
///
/// Uses [ChangeNotifier] (Flutter SDK, not a third-party state package) to
/// notify [AccountsPage] of state changes — no state-management dependency
/// exists anywhere in this codebase yet, so this is the minimal-footprint
/// choice consistent with "no custom state framework."
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) —
/// this ViewModel never invents or hardcodes a workspace identifier, and
/// reloads automatically when [WorkspaceContext] reports a switch.
final class AccountsViewModel extends ChangeNotifier {
  AccountsViewModel({
    required GetAccountsUseCase getAccountsUseCase,
    required CreateAccountUseCase createAccountUseCase,
    required UpdateAccountUseCase updateAccountUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required GetAccountBalanceUseCase getAccountBalanceUseCase,
    required WorkspaceContext workspaceContext,
    required FinanceChangeSignal financeChangeSignal,
  })  : _getAccountsUseCase = getAccountsUseCase,
        _createAccountUseCase = createAccountUseCase,
        _updateAccountUseCase = updateAccountUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        _getAccountBalanceUseCase = getAccountBalanceUseCase,
        _workspaceContext = workspaceContext,
        _financeChangeSignal = financeChangeSignal {
    _workspaceContext.addListener(_handleWorkspaceChanged);
    _financeChangeSignal.addListener(_handleFinanceChanged);
  }

  final WorkspaceContext _workspaceContext;
  final FinanceChangeSignal _financeChangeSignal;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetAccountsUseCase _getAccountsUseCase;
  final CreateAccountUseCase _createAccountUseCase;
  final UpdateAccountUseCase _updateAccountUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final GetAccountBalanceUseCase _getAccountBalanceUseCase;

  /// Reloads the account list for the newly-active workspace.
  ///
  /// This is presentation-layer plumbing, not a business rule: it does not
  /// decide *which* workspace is active (that's [WorkspaceContext]'s job)
  /// or *how* to filter/validate accounts (that's the use cases' job) — it
  /// only re-triggers the same [load] this ViewModel already performs on
  /// first mount.
  void _handleWorkspaceChanged() {
    load();
  }

  /// Reacts to a transaction mutation on [TransactionsViewModel] (create,
  /// update, delete, restore, transfer) by refreshing balances — this is
  /// presentation-layer plumbing only, not a business rule; it does not
  /// decide *how* a balance is computed (that's still
  /// [GetAccountBalanceUseCase]'s job), only *when* to recompute it.
  void _handleFinanceChanged() {
    refresh();
  }

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    _financeChangeSignal.removeListener(_handleFinanceChanged);
    super.dispose();
  }

  AsyncState<List<AccountListItem>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with items), or error.
  AsyncState<List<AccountListItem>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads,
  /// rather than reverting to a full-screen loading spinner.
  bool get isRefreshing => _isRefreshing;

  /// Loads accounts for the first time (or after an error), showing the
  /// full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads accounts while keeping the current list visible ([isRefreshing]
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
      GetAccountsInput(workspaceId: workspaceId, includeInactive: true),
    );

    if (accountsResult.isFailure) {
      _state = AsyncState.error(accountsResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    final accounts = accountsResult.valueOrNull!;
    final balanceResults = await Future.wait(
      accounts.map(
        (account) => _getAccountBalanceUseCase.execute(
          GetAccountBalanceInput(accountId: account.id, workspaceId: workspaceId),
        ),
      ),
    );

    final items = [
      for (var i = 0; i < accounts.length; i++)
        AccountListItem(
          account: accounts[i],
          // Falls back to a zero balance for display only if the balance
          // computation itself fails; the account is still shown rather than
          // dropped from the list.
          balance: balanceResults[i].valueOrNull ??
              Money(amount: Decimal.zero, currency: accounts[i].currency),
        ),
    ];

    _state = AsyncState.success(items);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Creates a new account, then reloads the list on success.
  ///
  /// Returns the [Result] from [CreateAccountUseCase] unchanged so the page
  /// can display a failure message without this ViewModel reinterpreting or
  /// duplicating the use case's validation.
  Future<Result<Account>> createAccount({
    required String name,
    required AccountType type,
    required CurrencyCode currency,
    required Money initialBalance,
  }) async {
    final result = await _createAccountUseCase.execute(CreateAccountInput(
      workspaceId: workspaceId,
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Updates an existing account's name and/or active flag, then reloads the
  /// list on success.
  Future<Result<Account>> updateAccount({
    required AccountId accountId,
    String? name,
    bool? isActive,
  }) async {
    final result = await _updateAccountUseCase.execute(UpdateAccountInput(
      accountId: accountId,
      workspaceId: workspaceId,
      name: name,
      isActive: isActive,
    ));
    if (result.isSuccess) await load();
    return result;
  }

  /// Soft-deletes an account, then reloads the list on success.
  ///
  /// If [AccountCanBeDeletedSpecification] (enforced inside
  /// [DeleteAccountUseCase]) rejects the deletion — e.g. the account still
  /// has active transactions — the returned [Result.failure] carries that
  /// exact message for the page to display. This ViewModel does not
  /// re-check or duplicate that rule.
  Future<Result<void>> deleteAccount(AccountId accountId) async {
    final result = await _deleteAccountUseCase.execute(DeleteAccountInput(
      accountId: accountId,
      workspaceId: workspaceId,
    ));
    if (result.isSuccess) await load();
    return result;
  }
}
