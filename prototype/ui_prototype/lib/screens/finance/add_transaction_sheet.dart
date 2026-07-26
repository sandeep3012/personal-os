import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import '../../fake_data/fake_data.dart';
import '../../shared/widgets/app_bottom_sheet.dart';

/// DOC-034 Part B §4.3 — Add/Edit Transaction bottom sheet.
void showAddTransactionSheet(BuildContext context, {FakeTransaction? existing}) {
  showAppBottomSheet(
    context: context,
    title: existing == null ? 'Add Transaction' : 'Edit Transaction',
    builder: (context) => _AddTransactionForm(existing: existing),
  );
}

class _AddTransactionForm extends StatefulWidget {
  const _AddTransactionForm({this.existing});
  final FakeTransaction? existing;

  @override
  State<_AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<_AddTransactionForm> {
  late int _segment = (widget.existing?.amount ?? -1) >= 0 ? 1 : 0;
  late final _amountController = TextEditingController(
    text: widget.existing != null ? widget.existing!.amount.abs().toStringAsFixed(0) : '',
  );

  @override
  Widget build(BuildContext context) {
    final canSave = _amountController.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Expense')),
            ButtonSegment(value: 1, label: Text('Income')),
          ],
          selected: {_segment},
          onSelectionChanged: (s) => setState(() => _segment = s.first),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Amount', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: Theme.of(context).textTheme.headlineMedium,
          decoration: const InputDecoration(prefixText: '₹ '),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Account', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: widget.existing?.account ?? FakeData.accounts.first.name,
          items: [for (final a in FakeData.accounts) DropdownMenuItem(value: a.name, child: Text(a.name))],
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Category', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: widget.existing?.category ?? 'Food',
          items: const [
            DropdownMenuItem(value: 'Food', child: Text('Food')),
            DropdownMenuItem(value: 'Transport', child: Text('Transport')),
            DropdownMenuItem(value: 'Income', child: Text('Income')),
            DropdownMenuItem(value: 'Bills', child: Text('Bills')),
          ],
          onChanged: (_) {},
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: FilledButton(
                onPressed: canSave
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaction added')),
                        );
                      }
                    : null,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
