import 'package:flutter/foundation.dart';

/// Which Finance screen a page belongs to, for highlighting the active
/// entry in [FinanceNavigationDrawer].
enum FinanceNavRoute { dashboard, accounts, transactions, categories }

/// App-layer-provided navigation callbacks shared by every Finance page.
///
/// Mirrors the callback pattern [FinanceHomePage] already used for its Quick
/// Actions (`onOpenAccounts`/`onOpenTransactions`) — feature packages never
/// import `go_router` directly (ADR-003); the app layer supplies these
/// callbacks (typically wrapping `context.goNamed(...)`) when constructing
/// each page.
///
/// All fields are optional: a page shows a drawer entry only when the
/// corresponding callback is non-null, exactly like the existing Quick
/// Action buttons.
final class FinanceNavCallbacks {
  const FinanceNavCallbacks({
    this.onOpenDashboard,
    this.onOpenAccounts,
    this.onOpenTransactions,
    this.onOpenCategories,
    this.onOpenDiagnostics,
  });

  final VoidCallback? onOpenDashboard;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenTransactions;
  final VoidCallback? onOpenCategories;

  /// Opens the platform diagnostics screen (the former application home,
  /// now a developer-facing screen owned by the app shell, not Finance).
  final VoidCallback? onOpenDiagnostics;
}
