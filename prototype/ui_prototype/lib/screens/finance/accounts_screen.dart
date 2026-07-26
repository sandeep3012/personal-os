import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/generic_tile.dart';
import 'account_details_screen.dart';
import 'add_transaction_sheet.dart';
import 'transactions_screen.dart';

/// DOC-034 Part B §4.1 — Accounts (Finance's home screen).
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TransactionsScreen()),
            ),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Worth', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                Text('₹${FakeData.netWorth.toStringAsFixed(0)}', style: textTheme.headlineMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Accounts', style: textTheme.titleMedium),
          ),
          for (final a in FakeData.accounts)
            GenericTile(
              icon: a.icon,
              iconColor: semantic.moduleAccent('finance'),
              title: a.name,
              trailing: '${a.balance < 0 ? '−' : ''}₹${a.balance.abs().toStringAsFixed(0)}',
              trailingColor: a.balance < 0 ? semantic.negative : null,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AccountDetailsScreen(account: a)),
              ),
            ),
        ],
      ),
    );
  }
}
