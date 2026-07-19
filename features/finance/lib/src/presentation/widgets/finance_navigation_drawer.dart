import 'package:feature_finance/src/presentation/navigation/finance_nav_callbacks.dart';
import 'package:flutter/material.dart';

/// The shared navigation surface for every Finance page: Dashboard,
/// Accounts, Transactions, Categories, plus an exit to platform
/// Diagnostics.
///
/// Presentation-only — every action is a callback supplied by the app layer
/// via [FinanceNavCallbacks] (ADR-003); this widget never imports
/// `go_router` and never decides *how* navigation happens, only *what* the
/// user tapped. An entry is omitted entirely when its callback is null,
/// matching the existing Quick Actions convention.
final class FinanceNavigationDrawer extends StatelessWidget {
  const FinanceNavigationDrawer({
    super.key,
    required this.callbacks,
    this.currentRoute,
  });

  final FinanceNavCallbacks callbacks;

  /// The screen this drawer is shown on, so its entry can be highlighted
  /// and disabled (no point navigating to the page you're already on).
  final FinanceNavRoute? currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Finance'),
              ),
            ),
            _entry(
              context,
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              route: FinanceNavRoute.dashboard,
              onTap: callbacks.onOpenDashboard,
            ),
            _entry(
              context,
              icon: Icons.account_balance_wallet_outlined,
              label: 'Accounts',
              route: FinanceNavRoute.accounts,
              onTap: callbacks.onOpenAccounts,
            ),
            _entry(
              context,
              icon: Icons.receipt_long_outlined,
              label: 'Transactions',
              route: FinanceNavRoute.transactions,
              onTap: callbacks.onOpenTransactions,
            ),
            _entry(
              context,
              icon: Icons.category_outlined,
              label: 'Categories',
              route: FinanceNavRoute.categories,
              onTap: callbacks.onOpenCategories,
            ),
            if (callbacks.onOpenDiagnostics != null) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.developer_mode_outlined),
                title: const Text('Diagnostics'),
                onTap: () {
                  Navigator.of(context).pop();
                  callbacks.onOpenDiagnostics!();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entry(
    BuildContext context, {
    required IconData icon,
    required String label,
    required FinanceNavRoute route,
    required VoidCallback? onTap,
  }) {
    if (onTap == null) return const SizedBox.shrink();
    final isCurrent = route == currentRoute;
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isCurrent,
      enabled: !isCurrent,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
