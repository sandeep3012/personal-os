import 'package:decimal/decimal.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_finance/src/domain/entities/account.dart';
import 'package:feature_finance/src/domain/value_objects/account_type.dart';
import 'package:feature_finance/src/domain/value_objects/currency_code.dart';
import 'package:feature_finance/src/domain/value_objects/money.dart';
import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/widgets/finance_navigation_drawer.dart';
import 'package:flutter/material.dart';

/// The account list screen.
///
/// Supports viewing accounts with balances, creating, editing, soft-deleting
/// (long-press → confirm), and pull-to-refresh, entirely through
/// [AccountsViewModel]. Contains no business logic: every action delegates
/// to a use case and only displays whatever [Result] comes back.
///
/// Built entirely from `package:design_system` components (Milestone 4
/// migration) — [AppStateSwitcher] for Loading/Empty/Error, [AccountTile]
/// for each row, [showAppInputSurface] for create/edit.
///
/// [navCallbacks], when supplied, renders the shared Finance navigation
/// drawer (ADR-003 — callback-based, no `go_router` import here).
final class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key, required this.viewModel, this.navCallbacks});

  final AccountsViewModel viewModel;
  final FinanceNavCallbacks? navCallbacks;

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Accounts')),
        drawer: widget.navCallbacks == null
            ? null
            : FinanceNavigationDrawer(
                callbacks: widget.navCallbacks!,
                currentRoute: FinanceNavRoute.accounts,
              ),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<AccountListItem>>(
            state: widget.viewModel.state,
            isEmpty: (items) => items.isEmpty,
            emptyIcon: Icons.account_balance_wallet_outlined,
            emptyTitle: 'No accounts yet',
            emptyMessage: 'Track where your money lives',
            emptyActionLabel: 'Add Account',
            onEmptyAction: () => _openAccountForm(context),
            onRetry: widget.viewModel.load,
            successBuilder: (context, items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AccountTile(
                  icon: _iconFor(item.account.type),
                  name: item.account.name,
                  subtitle: item.account.type.name,
                  balanceText: MoneyText.format(
                    item.balance.amount,
                    item.balance.currency.value,
                  ),
                  onTap: () => _openAccountForm(context, existing: item.account),
                  onLongPress: () => _confirmDelete(context, item.account),
                );
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openAccountForm(context),
          tooltip: 'Add account',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  IconData _iconFor(AccountType type) => switch (type) {
        AccountType.savings => Icons.savings_outlined,
        AccountType.checking => Icons.account_balance_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.cash => Icons.payments_outlined,
        AccountType.investment => Icons.trending_up_outlined,
      };

  Future<void> _openAccountForm(BuildContext context, {Account? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final currencyController =
        TextEditingController(text: existing?.currency.value ?? 'INR');
    final balanceController = TextEditingController(
      text: existing == null ? '0' : existing.initialBalance.amount.toString(),
    );
    final selectedType = ValueNotifier<AccountType>(existing?.type ?? AccountType.savings);

    return showAppInputSurface(
      context,
      title: existing == null ? 'Create Account' : 'Edit Account',
      onSave: () => _saveAccountForm(
        context,
        existing: existing,
        nameController: nameController,
        currencyController: currencyController,
        balanceController: balanceController,
        selectedType: selectedType,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppFormField(label: 'Name', controller: nameController, autofocus: true),
          if (existing == null) ...[
            const SizedBox(height: AppSpacing.sm),
            ValueListenableBuilder<AccountType>(
              valueListenable: selectedType,
              builder: (context, type, _) => DropdownButtonFormField<AccountType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Account Type'),
                items: AccountType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedType.value = value;
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Currency (e.g. INR)',
              controller: currencyController,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppFormField(
              label: 'Initial Balance',
              controller: balanceController,
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveAccountForm(
    BuildContext context, {
    required Account? existing,
    required TextEditingController nameController,
    required TextEditingController currencyController,
    required TextEditingController balanceController,
    required ValueNotifier<AccountType> selectedType,
  }) async {
    Navigator.of(context).pop();

    if (existing == null) {
      CurrencyCode currency;
      Decimal amount;
      try {
        currency = CurrencyCode(currencyController.text.toUpperCase());
        amount = Decimal.parse(
          balanceController.text.isEmpty ? '0' : balanceController.text,
        );
      } catch (e) {
        if (!context.mounted) return;
        _showMessage(context, 'Invalid input: $e');
        return;
      }

      final result = await widget.viewModel.createAccount(
        name: nameController.text,
        type: selectedType.value,
        currency: currency,
        initialBalance: Money(amount: amount, currency: currency),
      );
      if (!context.mounted) return;
      if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
    } else {
      final result = await widget.viewModel.updateAccount(
        accountId: existing.id,
        name: nameController.text,
      );
      if (!context.mounted) return;
      if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Account account) {
    return showConfirmationDialog(
      context,
      itemDescription: '"${account.name}"',
      onConfirm: () async {
        final result = await widget.viewModel.deleteAccount(account.id);
        if (!context.mounted) return;
        if (result.isFailure) _showMessage(context, result.exceptionOrNull!.message);
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
