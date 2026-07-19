import 'package:design_system/design_system.dart';
import 'package:feature_finance/src/domain/entities/transaction.dart';
import 'package:feature_finance/src/domain/value_objects/transaction_type.dart';
import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:feature_finance/src/presentation/viewmodels/accounts_view_model.dart';
import 'package:feature_finance/src/presentation/viewmodels/finance_home_view_model.dart';
import 'package:feature_finance/src/presentation/widgets/finance_navigation_drawer.dart';
import 'package:flutter/material.dart';

/// The Finance feature's landing page: total balance, income/expense
/// summary, account overview, and recent activity.
///
/// Built entirely from `package:design_system` components (Milestone 4
/// migration) — [AppStateSwitcher] for Loading/Empty/Error, [SectionHeader]
/// for every section title, [StatCard] for the summary figures,
/// [AccountTile]/[TransactionTile] for the overview lists, and
/// [QuickActionButton] for the navigation shortcuts.
///
/// [navCallbacks] supplies both the Quick Action buttons and the navigation
/// drawer's destinations. The app layer wires each callback to real
/// navigation (e.g. `context.goNamed(FinanceRoutes.accounts.name)`) — this
/// page never imports `go_router` directly (ADR-003: feature packages
/// navigate only through app-layer-provided callbacks or
/// `NavigationService`, never by importing go_router themselves).
final class FinanceHomePage extends StatefulWidget {
  const FinanceHomePage({
    super.key,
    required this.viewModel,
    this.navCallbacks,
  });

  final FinanceHomeViewModel viewModel;
  final FinanceNavCallbacks? navCallbacks;

  @override
  State<FinanceHomePage> createState() => _FinanceHomePageState();
}

class _FinanceHomePageState extends State<FinanceHomePage> {
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
        appBar: AppBar(title: const Text('Finance')),
        drawer: widget.navCallbacks == null
            ? null
            : FinanceNavigationDrawer(
                callbacks: widget.navCallbacks!,
                currentRoute: FinanceNavRoute.dashboard,
              ),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<FinanceDashboardData>(
            state: widget.viewModel.state,
            isEmpty: (data) => data.accounts.isEmpty,
            emptyIcon: Icons.account_balance_wallet_outlined,
            emptyTitle: 'No accounts yet',
            onRetry: widget.viewModel.load,
            successBuilder: (context, data) => ListView(
              children: [
                _SummaryCards(data: data),
                _QuickActions(
                  onOpenAccounts: widget.navCallbacks?.onOpenAccounts,
                  onOpenTransactions: widget.navCallbacks?.onOpenTransactions,
                ),
                SectionHeader(
                  title: 'Accounts',
                  onSeeAll: widget.navCallbacks?.onOpenAccounts,
                ),
                _AccountOverview(accounts: data.accounts),
                SectionHeader(
                  title: 'Recent Transactions',
                  onSeeAll: widget.navCallbacks?.onOpenTransactions,
                ),
                _RecentTransactions(transactions: data.recentTransactions),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.data});

  final FinanceDashboardData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Total Balance'),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              for (final entry in data.totalBalanceByCurrency.entries)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: entry.key,
                    value: entry.value.amount.toDouble(),
                    valueFormatter: (v) =>
                        MoneyText.format(entry.value.amount, entry.key),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: StatCard(
                  icon: Icons.arrow_upward,
                  label: 'Income (this month)',
                  value: data.totalIncome.amount.toDouble(),
                  valueFormatter: (v) => MoneyText.format(
                    data.totalIncome.amount,
                    data.totalIncome.currency.value,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: StatCard(
                  icon: Icons.arrow_downward,
                  label: 'Expenses (this month)',
                  value: data.totalExpenses.amount.toDouble(),
                  valueFormatter: (v) => MoneyText.format(
                    data.totalExpenses.amount,
                    data.totalExpenses.currency.value,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Semantics(
                  label: 'Net position this month: '
                      '${MoneyText.format(data.netPosition.amount, data.netPosition.currency.value)}',
                  excludeSemantics: true,
                  child: StatCard(
                    icon: Icons.trending_up,
                    label: 'Net Position (this month)',
                    value: data.netPosition.amount.toDouble(),
                    valueFormatter: (v) => MoneyText.format(
                      data.netPosition.amount,
                      data.netPosition.currency.value,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({this.onOpenAccounts, this.onOpenTransactions});

  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenTransactions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (onOpenAccounts != null)
            QuickActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: 'View Accounts',
              onTap: onOpenAccounts!,
            ),
          if (onOpenTransactions != null)
            QuickActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'View Transactions',
              onTap: onOpenTransactions!,
            ),
        ],
      ),
    );
  }
}

class _AccountOverview extends StatelessWidget {
  const _AccountOverview({required this.accounts});

  final List<AccountListItem> accounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in accounts)
          AccountTile(
            icon: Icons.account_balance_wallet_outlined,
            name: item.account.name,
            subtitle: item.account.type.name,
            balanceText: MoneyText.format(
              item.balance.amount,
              item.balance.currency.value,
            ),
          ),
      ],
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text('No recent transactions'),
      );
    }
    return Column(
      children: [
        for (final txn in transactions)
          TransactionTile(
            type: _tileTypeFor(txn),
            title: txn.payee?.value ?? txn.type.name,
            subtitle: txn.note ?? txn.type.name,
            amountText: MoneyText.format(txn.amount.amount, txn.amount.currency.value),
          ),
      ],
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
}
