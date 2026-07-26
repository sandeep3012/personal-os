import 'package:decimal/decimal.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/category_id.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/domain/value_objects/payee.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_date.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:feature_finance/src/presentation/viewmodels/transactions_view_model.dart';
import 'package:feature_finance/src/presentation/widgets/finance_navigation_drawer.dart';
import 'package:flutter/material.dart';

enum _EntryKind { expense, income, transfer }

/// The transaction list screen — also the home for creating Transfers, since
/// Finance has no separate Transfers route (transfers are Transactions with
/// a `transferCounterpartId`, not a distinct persisted concept — DOC-031
/// §4.3).
///
/// Built entirely from `package:design_system` components (Milestone 4
/// migration) — [AppStateSwitcher] for Loading/Empty/Error, [FilterBar] for
/// the account/transfers filters, [TransactionTile] for each row (swipe to
/// delete — VPS §5.3.4), [showAppInputSurface] for create/edit.
///
/// Deletion follows the Material 3 Undo pattern (Milestone 5 Part A, revised
/// during Finance Stabilization): swiping a row deletes it immediately —
/// [TransactionsViewModel.deleteTransaction] is called right away, not
/// deferred behind the SnackBar's timer, so the delete is never lost if the
/// app closes before the SnackBar would have closed on its own (the
/// deferred version of this had exactly that data-loss window). Tapping
/// "UNDO" calls [TransactionsViewModel.restoreTransaction], which reverses
/// the already-committed soft-delete via the Finance-internal
/// `RestoreTransactionUseCase`.
///
/// [navCallbacks], when supplied, renders the shared Finance navigation
/// drawer (ADR-003 — callback-based, no `go_router` import here).
final class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key, required this.viewModel, this.navCallbacks});

  final TransactionsViewModel viewModel;
  final FinanceNavCallbacks? navCallbacks;

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Captured once from a stable, page-lifetime context (this State's own
    // `build` context) rather than inside an item's onDismissed callback —
    // by the time a Dismissible's own removal animation completes, that
    // row's BuildContext is being torn down, making `ScaffoldMessenger.of`
    // unreliable there. This one resolves to the ambient ScaffoldMessenger
    // (from MaterialApp) and stays valid for this page's whole lifetime.
    final messenger = ScaffoldMessenger.of(context);

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: AppSearchBar(
                    hintText: 'Search by payee',
                    controller: _searchController,
                    onChanged: widget.viewModel.setSearchQuery,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: _buildFilterBar(context),
                ),
              ],
            ),
          ),
        ),
        drawer: widget.navCallbacks == null
            ? null
            : FinanceNavigationDrawer(
                callbacks: widget.navCallbacks!,
                currentRoute: FinanceNavRoute.transactions,
              ),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<Transaction>>(
            state: widget.viewModel.state,
            isEmpty: (items) => items.isEmpty,
            emptyIcon: Icons.receipt_long_outlined,
            emptyTitle: 'No transactions yet',
            emptyMessage: 'Every expense and income will show up here',
            emptyActionLabel: 'Add Transaction',
            onEmptyAction: () => _openEntryForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, items) {
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final txn = items[index];
                  final isTransferLeg = txn.transferCounterpartId != null;
                  return TransactionTile(
                    type: _tileTypeFor(txn),
                    title: txn.payee?.value ?? txn.type.name,
                    subtitle: isTransferLeg
                        ? 'Transfer leg'
                        : (txn.note ?? txn.type.name),
                    amountText: MoneyText.format(
                      txn.amount.amount,
                      txn.amount.currency.value,
                    ),
                    onTap: () => _openEntryForm(context, existing: txn),
                    dismissKey: ValueKey(txn.id.value),
                    onDismissed: () => _handleSwipeToDelete(messenger, txn),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openEntryForm(context),
          tooltip: 'Add transaction or transfer',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  /// Deletes [txn] immediately, then shows the Undo SnackBar. Tapping UNDO
  /// calls [TransactionsViewModel.restoreTransaction] to reverse the
  /// already-committed soft-delete — see the class doc for why the delete
  /// itself is never deferred behind the SnackBar's timer.
  Future<void> _handleSwipeToDelete(
    ScaffoldMessengerState messenger,
    Transaction txn,
  ) async {
    final result = await widget.viewModel.deleteTransaction(txn.id);
    if (!mounted) return;

    if (result.isFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text(result.exceptionOrNull!.message)),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => widget.viewModel.restoreTransaction(txn.id),
        ),
      ),
    );
  }

  TransactionTileType _tileTypeFor(Transaction txn) {
    if (txn.transferCounterpartId != null) return TransactionTileType.transfer;
    return switch (txn.type) {
      TransactionType.expense => TransactionTileType.expense,
      TransactionType.income => TransactionTileType.income,
      TransactionType.transfer => TransactionTileType.transfer,
    };
  }

  Widget _buildFilterBar(BuildContext context) {
    final viewModel = widget.viewModel;
    final filters = <FilterOption>[
      FilterOption(
        label: 'All accounts',
        selected: viewModel.accountFilter == null,
        onSelected: (_) => viewModel.setAccountFilter(null),
      ),
      for (final account in viewModel.accounts)
        FilterOption(
          label: account.name,
          selected: viewModel.accountFilter?.value == account.id.value,
          onSelected: (_) => viewModel.setAccountFilter(account.id),
        ),
      FilterOption(
        label: 'Transfers only',
        selected: viewModel.transfersOnly,
        onSelected: viewModel.setTransfersOnly,
      ),
    ];
    return FilterBar(filters: filters);
  }

  Future<void> _openEntryForm(BuildContext context, {Transaction? existing}) {
    if (existing != null) return _openEditDialog(context, existing);
    return _openCreateDialog(context);
  }

  Future<void> _openCreateDialog(BuildContext context) {
    final accounts = widget.viewModel.accounts;
    if (accounts.isEmpty) {
      _showMessage(context, 'Create an account first.');
      return Future.value();
    }

    final kind = ValueNotifier(_EntryKind.expense);
    final fromAccount = ValueNotifier(accounts.first);
    final toAccount = ValueNotifier(accounts.length > 1 ? accounts[1] : accounts.first);
    final amountController = TextEditingController(text: '0');
    final payeeController = TextEditingController();
    final categoryController = TextEditingController();
    final noteController = TextEditingController();

    return showAppInputSurface(
      context,
      title: 'Add Transaction',
      onSave: () => _saveCreateForm(
        context,
        kind: kind.value,
        fromAccount: fromAccount.value,
        toAccount: toAccount.value,
        amountController: amountController,
        payeeController: payeeController,
        categoryController: categoryController,
        noteController: noteController,
      ),
      child: ValueListenableBuilder<_EntryKind>(
        valueListenable: kind,
        builder: (context, currentKind, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<_EntryKind>(
              segments: const [
                ButtonSegment(value: _EntryKind.expense, label: Text('Expense')),
                ButtonSegment(value: _EntryKind.income, label: Text('Income')),
                ButtonSegment(value: _EntryKind.transfer, label: Text('Transfer')),
              ],
              selected: {currentKind},
              onSelectionChanged: (selection) => kind.value = selection.first,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (currentKind == _EntryKind.transfer) ...[
              ValueListenableBuilder<Account>(
                valueListenable: fromAccount,
                builder: (context, value, _) => DropdownButtonFormField<Account>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'From'),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                      .toList(),
                  onChanged: (a) {
                    if (a != null) fromAccount.value = a;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ValueListenableBuilder<Account>(
                valueListenable: toAccount,
                builder: (context, value, _) => DropdownButtonFormField<Account>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'To'),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                      .toList(),
                  onChanged: (a) {
                    if (a != null) toAccount.value = a;
                  },
                ),
              ),
            ] else
              ValueListenableBuilder<Account>(
                valueListenable: fromAccount,
                builder: (context, value, _) => DropdownButtonFormField<Account>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'Account'),
                  items: accounts
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                      .toList(),
                  onChanged: (a) {
                    if (a != null) fromAccount.value = a;
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Amount',
              controller: amountController,
              keyboardType: TextInputType.number,
            ),
            if (currentKind != _EntryKind.transfer) ...[
              const SizedBox(height: AppSpacing.sm),
              AppFormField(label: 'Payee (optional)', controller: payeeController),
              const SizedBox(height: AppSpacing.sm),
              AppFormField(label: 'Category (optional)', controller: categoryController),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppFormField(label: 'Note (optional)', controller: noteController),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCreateForm(
    BuildContext context, {
    required _EntryKind kind,
    required Account fromAccount,
    required Account toAccount,
    required TextEditingController amountController,
    required TextEditingController payeeController,
    required TextEditingController categoryController,
    required TextEditingController noteController,
  }) async {
    Navigator.of(context).pop();

    Decimal amount;
    try {
      amount = Decimal.parse(amountController.text.isEmpty ? '0' : amountController.text);
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(context, 'Invalid amount: $e');
      return;
    }

    final money = Money(amount: amount, currency: fromAccount.currency);
    final date = TransactionDate(DateTime.now());
    final payee = payeeController.text.isEmpty ? null : Payee(payeeController.text);
    final category =
        categoryController.text.isEmpty ? null : CategoryId(categoryController.text);
    final note = noteController.text.isEmpty ? null : noteController.text;

    final result = switch (kind) {
      _EntryKind.expense => await widget.viewModel.addExpense(
          accountId: fromAccount.id,
          amount: money,
          date: date,
          payee: payee,
          categoryId: category,
          note: note,
        ),
      _EntryKind.income => await widget.viewModel.addIncome(
          accountId: fromAccount.id,
          amount: money,
          date: date,
          payee: payee,
          categoryId: category,
          note: note,
        ),
      _EntryKind.transfer => await widget.viewModel.createTransfer(
          fromAccountId: fromAccount.id,
          toAccountId: toAccount.id,
          amount: money,
          date: date,
          note: note,
        ),
    };

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  Future<void> _openEditDialog(BuildContext context, Transaction existing) {
    final amountController =
        TextEditingController(text: existing.amount.amount.toString());
    final noteController = TextEditingController(text: existing.note ?? '');

    return showAppInputSurface(
      context,
      title: 'Edit Transaction',
      onSave: () => _saveEditForm(
        context,
        existing: existing,
        amountController: amountController,
        noteController: noteController,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormField(
            label: 'Amount',
            controller: amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppFormField(label: 'Note', controller: noteController),
        ],
      ),
    );
  }

  Future<void> _saveEditForm(
    BuildContext context, {
    required Transaction existing,
    required TextEditingController amountController,
    required TextEditingController noteController,
  }) async {
    Navigator.of(context).pop();

    Decimal amount;
    try {
      amount = Decimal.parse(
        amountController.text.isEmpty ? '0' : amountController.text,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showMessage(context, 'Invalid amount: $e');
      return;
    }

    final result = await widget.viewModel.updateTransaction(
      transactionId: existing.id,
      amount: Money(amount: amount, currency: existing.amount.currency),
      note: noteController.text.isEmpty ? null : noteController.text,
    );

    if (!context.mounted) return;
    if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
