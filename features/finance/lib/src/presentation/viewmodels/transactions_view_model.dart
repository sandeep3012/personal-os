import 'package:application/application.dart';
import 'package:feature_finance/src/application/use_cases/account/get_accounts_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_expense_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/add_income_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/create_transfer_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/delete_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/query_transactions_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/restore_transaction_use_case.dart';
import 'package:feature_finance/src/application/use_cases/transaction/update_transaction_use_case.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/account_id.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_id.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_query.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_change_signal.dart';
import 'package:flutter/foundation.dart';
import 'package:platform_core/platform_core.dart';

/// Drives [TransactionsPage]: lists transactions (optionally filtered by
/// account/category, or restricted to transfer legs), and exposes
/// create/update/delete for plain transactions plus create for transfers.
///
/// Depends only on use cases — never on a repository, DAO, or specification
/// directly, mirroring [AccountsViewModel] exactly (ADR-004). Transfers are
/// always created via [CreateTransferUseCase], which itself persists both
/// legs atomically through [ITransactionRepository.saveTransferPair] — this
/// ViewModel never touches a repository pair directly.
///
/// The active workspace is obtained from [WorkspaceContext] (ADR-004) —
/// this ViewModel never invents or hardcodes a workspace identifier, and
/// reloads automatically when [WorkspaceContext] reports a switch.
final class TransactionsViewModel extends ChangeNotifier {
  TransactionsViewModel({
    required GetAccountsUseCase getAccountsUseCase,
    required QueryTransactionsUseCase queryTransactionsUseCase,
    required AddExpenseUseCase addExpenseUseCase,
    required AddIncomeUseCase addIncomeUseCase,
    required UpdateTransactionUseCase updateTransactionUseCase,
    required DeleteTransactionUseCase deleteTransactionUseCase,
    required RestoreTransactionUseCase restoreTransactionUseCase,
    required CreateTransferUseCase createTransferUseCase,
    required WorkspaceContext workspaceContext,
    required FinanceChangeSignal financeChangeSignal,
  })  : _getAccountsUseCase = getAccountsUseCase,
        _queryTransactionsUseCase = queryTransactionsUseCase,
        _addExpenseUseCase = addExpenseUseCase,
        _addIncomeUseCase = addIncomeUseCase,
        _updateTransactionUseCase = updateTransactionUseCase,
        _deleteTransactionUseCase = deleteTransactionUseCase,
        _restoreTransactionUseCase = restoreTransactionUseCase,
        _createTransferUseCase = createTransferUseCase,
        _workspaceContext = workspaceContext,
        _financeChangeSignal = financeChangeSignal {
    _workspaceContext.addListener(_handleWorkspaceChanged);
  }

  final WorkspaceContext _workspaceContext;
  final FinanceChangeSignal _financeChangeSignal;

  /// The workspace this ViewModel currently operates within — always read
  /// live from [WorkspaceContext], never cached or hardcoded.
  String get workspaceId => _workspaceContext.workspaceId;

  final GetAccountsUseCase _getAccountsUseCase;
  final QueryTransactionsUseCase _queryTransactionsUseCase;
  final AddExpenseUseCase _addExpenseUseCase;
  final AddIncomeUseCase _addIncomeUseCase;
  final UpdateTransactionUseCase _updateTransactionUseCase;
  final DeleteTransactionUseCase _deleteTransactionUseCase;
  final RestoreTransactionUseCase _restoreTransactionUseCase;
  final CreateTransferUseCase _createTransferUseCase;

  void _handleWorkspaceChanged() => load();

  @override
  void dispose() {
    _workspaceContext.removeListener(_handleWorkspaceChanged);
    super.dispose();
  }

  AsyncState<List<Transaction>> _state = const AsyncState.loading();

  /// The current load state: loading, success (with items), or error.
  AsyncState<List<Transaction>> get state => _state;

  var _isRefreshing = false;

  /// Whether a [refresh] is in progress. Distinct from [state] so a pull-to-
  /// refresh can keep showing the existing list while new data loads.
  bool get isRefreshing => _isRefreshing;

  List<Account> _accounts = const [];

  /// Accounts available for filtering and for the account picker in the
  /// create/transfer dialogs. Populated as a side effect of [load] — this
  /// is presentation-layer convenience, not a new business capability
  /// (accounts already come from [GetAccountsUseCase], unchanged).
  List<Account> get accounts => List.unmodifiable(_accounts);

  AccountId? _accountFilter;

  /// The current account filter, or `null` for "all accounts". UI-only
  /// state — filtering itself is performed by [QueryTransactionsUseCase].
  AccountId? get accountFilter => _accountFilter;

  CategoryId? _categoryFilter;

  /// The current category filter, or `null` for "all categories".
  /// Categories are opaque, platform-owned references (DOC-031 §5.1) — this
  /// ViewModel does not validate or enumerate them.
  CategoryId? get categoryFilter => _categoryFilter;

  var _transfersOnly = false;

  /// Whether the list is restricted to transfer legs only (i.e.
  /// `transaction.transferCounterpartId != null`) — this is how "transfer
  /// history" is presented, since transfers are Transactions, not a
  /// separate persisted concept (DOC-031 §4.3).
  bool get transfersOnly => _transfersOnly;

  var _searchQuery = '';

  /// The current payee search text, or `''` for no search filter. UI-only
  /// state — the actual filtering is performed by
  /// [QueryTransactionsUseCase] via [TransactionQuery.payeeNameContains],
  /// which already existed and was already tested; this ViewModel only
  /// wires it to the search field (VPS §2, design principle #6).
  String get searchQuery => _searchQuery;

  /// Updates the payee search text and reloads. Passing `''` clears the
  /// search filter — preserves whatever account/category/transfers filters
  /// are already active.
  void setSearchQuery(String query) {
    _searchQuery = query;
    load();
  }

  /// Updates the account filter and reloads.
  void setAccountFilter(AccountId? accountId) {
    _accountFilter = accountId;
    load();
  }

  /// Updates the category filter and reloads.
  void setCategoryFilter(CategoryId? categoryId) {
    _categoryFilter = categoryId;
    load();
  }

  /// Toggles showing only transfer legs and reloads.
  void setTransfersOnly(bool value) {
    _transfersOnly = value;
    load();
  }

  /// Loads accounts and transactions for the first time (or after an
  /// error), showing the full-screen loading state.
  Future<void> load() => _fetch(isRefresh: false);

  /// Reloads while keeping the current list visible ([isRefreshing] becomes
  /// `true` instead of resetting [state] to loading).
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
    if (accountsResult.isSuccess) {
      _accounts = accountsResult.valueOrNull!;
    }

    final queryResult = await _queryTransactionsUseCase.execute(TransactionQuery(
      workspaceId: workspaceId,
      accountId: _accountFilter,
      categoryId: _categoryFilter,
      payeeNameContains: _searchQuery.isEmpty ? null : _searchQuery,
      pageSize: 200,
    ));

    if (queryResult.isFailure) {
      _state = AsyncState.error(queryResult.exceptionOrNull!);
      _isRefreshing = false;
      notifyListeners();
      return;
    }

    var items = queryResult.valueOrNull!.items;
    if (_transfersOnly) {
      items = items.where((t) => t.transferCounterpartId != null).toList();
    }

    _state = AsyncState.success(items);
    _isRefreshing = false;
    notifyListeners();
  }

  /// Records an expense, then reloads on success.
  Future<Result<Transaction>> addExpense({
    required AccountId accountId,
    required Money amount,
    required TransactionDate date,
    Payee? payee,
    CategoryId? categoryId,
    String? note,
  }) async {
    final result = await _addExpenseUseCase.execute(AddExpenseInput(
      workspaceId: workspaceId,
      accountId: accountId,
      amount: amount,
      date: date,
      payee: payee,
      categoryId: categoryId,
      note: note,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }

  /// Records income, then reloads on success.
  Future<Result<Transaction>> addIncome({
    required AccountId accountId,
    required Money amount,
    required TransactionDate date,
    Payee? payee,
    CategoryId? categoryId,
    String? note,
  }) async {
    final result = await _addIncomeUseCase.execute(AddIncomeInput(
      workspaceId: workspaceId,
      accountId: accountId,
      amount: amount,
      date: date,
      payee: payee,
      categoryId: categoryId,
      note: note,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }

  /// Updates a transaction's mutable fields, then reloads on success.
  ///
  /// Type and account are structurally immutable (omitted from
  /// [UpdateTransactionInput] by the use case itself) — including for a
  /// transfer leg, whose counterpart is left untouched by this call, exactly
  /// as [UpdateTransactionUseCase] already behaves.
  Future<Result<Transaction>> updateTransaction({
    required TransactionId transactionId,
    Money? amount,
    TransactionDate? date,
    Payee? payee,
    CategoryId? categoryId,
    String? note,
  }) async {
    final result = await _updateTransactionUseCase.execute(UpdateTransactionInput(
      transactionId: transactionId,
      workspaceId: workspaceId,
      amount: amount,
      date: date,
      payee: payee,
      categoryId: categoryId,
      note: note,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }

  /// Soft-deletes a single transaction (including a single transfer leg,
  /// which is all [DeleteTransactionUseCase] supports today — its
  /// counterpart is left in place, unchanged from existing use-case
  /// behavior), then reloads on success.
  ///
  /// Deletion happens immediately (not deferred behind an Undo timer) so it
  /// is never lost to the app closing before a timer fires — [TransactionsPage]
  /// pairs this with [restoreTransaction] to offer Undo on an
  /// already-committed delete instead.
  Future<Result<void>> deleteTransaction(TransactionId transactionId) async {
    final result = await _deleteTransactionUseCase.execute(DeleteTransactionInput(
      transactionId: transactionId,
      workspaceId: workspaceId,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }

  /// Reverses a [deleteTransaction] call — the backing action for the
  /// "UNDO" button on the delete SnackBar, then reloads on success.
  ///
  /// Finance-internal: [RestoreTransactionUseCase] only ever restores a
  /// transaction that is currently soft-deleted, and this method exists
  /// solely to support Undo-after-delete, not a general restore capability.
  Future<Result<void>> restoreTransaction(TransactionId transactionId) async {
    final result = await _restoreTransactionUseCase.execute(RestoreTransactionInput(
      transactionId: transactionId,
      workspaceId: workspaceId,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }

  /// Creates a transfer between two accounts, then reloads on success.
  ///
  /// Delegates entirely to [CreateTransferUseCase], which enforces
  /// [TransferCanBeCreatedSpecification] and persists both legs atomically
  /// via [ITransactionRepository.saveTransferPair] — this ViewModel never
  /// constructs or persists transfer legs itself.
  Future<Result<CreateTransferOutput>> createTransfer({
    required AccountId fromAccountId,
    required AccountId toAccountId,
    required Money amount,
    required TransactionDate date,
    String? note,
  }) async {
    final result = await _createTransferUseCase.execute(CreateTransferInput(
      workspaceId: workspaceId,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
      amount: amount,
      date: date,
      note: note,
    ));
    if (result.isSuccess) {
      _financeChangeSignal.notifyChanged();
      await load();
    }
    return result;
  }
}
