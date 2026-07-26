import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/generic_tile.dart';
import 'add_transaction_sheet.dart';

/// DOC-034 Part B §4.2 — Transactions, grouped by day, swipe-to-delete.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final List<FakeTransaction> _items = [...FakeData.transactions];
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;

    final filtered = _items.where((t) {
      if (_filter == 1) return t.amount > 0;
      if (_filter == 2) return t.amount < 0;
      return true;
    }).toList();

    final groups = <String, List<FakeTransaction>>{};
    for (final t in filtered) {
      groups.putIfAbsent(t.group, () => []).add(t);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showAddTransactionSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                ChoiceChip(label: const Text('All'), selected: _filter == 0, onSelected: (_) => setState(() => _filter = 0)),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('Income'), selected: _filter == 1, onSelected: (_) => setState(() => _filter = 1)),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(label: const Text('Expense'), selected: _filter == 2, onSelected: (_) => setState(() => _filter = 2)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: textTheme.labelMedium?.copyWith(color: Colors.grey, letterSpacing: 1.1),
                    ),
                  ),
                  for (final t in entry.value)
                    Dismissible(
                      key: ValueKey(t.title + t.group),
                      background: Container(
                        color: semantic.negative,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        setState(() => _items.remove(t));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${t.title} deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () => setState(() => _items.add(t)),
                            ),
                          ),
                        );
                      },
                      child: GenericTile(
                        icon: t.icon,
                        iconColor: semantic.moduleAccent('finance'),
                        title: t.title,
                        subtitle: '${t.category} · ${t.account}',
                        trailing: '${t.amount < 0 ? '−' : '+'}₹${t.amount.abs().toStringAsFixed(0)}',
                        trailingColor: t.amount < 0 ? null : semantic.positive,
                        onTap: () => showAddTransactionSheet(context, existing: t),
                      ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
