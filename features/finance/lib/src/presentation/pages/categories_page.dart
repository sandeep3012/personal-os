import 'package:design_system/design_system.dart';
import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:feature_finance/src/presentation/viewmodels/categories_view_model.dart';
import 'package:feature_finance/src/presentation/widgets/finance_navigation_drawer.dart';
import 'package:flutter/material.dart';

/// The category summary screen.
///
/// No create/edit/delete: DOC-031 §5.1 is explicit that Finance never
/// performs category CRUD — categories are opaque references owned by the
/// (not-yet-built) platform Classification Service. This page only
/// displays spending totals per category for the current month, derived
/// from transactions that already exist, with a client-side search filter.
///
/// Built entirely from `package:design_system` components (Milestone 4
/// migration) — [AppStateSwitcher] for Loading/Empty/Error, [AppSearchBar]
/// for the search field, [CategorySummaryTile] for each row.
///
/// [navCallbacks], when supplied, renders the shared Finance navigation
/// drawer (ADR-003 — callback-based, no `go_router` import here).
final class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key, required this.viewModel, this.navCallbacks});

  final CategoriesViewModel viewModel;
  final FinanceNavCallbacks? navCallbacks;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
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
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: AppSearchBar(
                hintText: 'Search categories',
                onChanged: widget.viewModel.setSearchQuery,
              ),
            ),
          ),
        ),
        drawer: widget.navCallbacks == null
            ? null
            : FinanceNavigationDrawer(
                callbacks: widget.navCallbacks!,
                currentRoute: FinanceNavRoute.categories,
              ),
        body: RefreshIndicator(
          onRefresh: widget.viewModel.refresh,
          child: AppStateSwitcher<List<CategorySummaryItem>>(
            state: widget.viewModel.state,
            isEmpty: (items) => items.isEmpty,
            emptyIcon: Icons.category_outlined,
            emptyTitle: 'No categorized spending yet',
            onRetry: widget.viewModel.load,
            successBuilder: (context, items) {
              final maxAmount = items
                  .map((item) => item.total.amount)
                  .fold<double>(0, (max, amount) {
                final value = amount.toDouble();
                return value > max ? value : max;
              });
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final proportion = maxAmount == 0
                      ? 0.0
                      : item.total.amount.toDouble() / maxAmount;
                  return CategorySummaryTile(
                    name: item.categoryId.value,
                    amountText: MoneyText.format(
                      item.total.amount,
                      item.total.currency.value,
                    ),
                    proportion: proportion,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
