import 'package:flutter/foundation.dart';

/// A single-purpose, Finance-internal signal: "a transaction mutation just
/// happened — anything showing a computed balance should refresh."
///
/// This is deliberately *not* a generic event bus and must not become one:
/// no event payload, no event types, no cross-feature reach. It exists
/// solely to solve one problem — [AccountsViewModel]/[FinanceHomeViewModel]
/// and [TransactionsViewModel] are independent `ChangeNotifier`s (each a DI
/// factory, one instance per page mount) with no way to hear about each
/// other's mutations, so a previously-mounted Accounts page (kept alive by
/// the app shell's `StatefulShellRoute.indexedStack`) could show a stale
/// balance after a transaction was created/edited/deleted/restored, or a
/// transfer made, on the Transactions page.
///
/// Registered as a lazy singleton in [FinanceModule] so every ViewModel
/// resolves the same instance — mirrors how [WorkspaceContext] is already
/// depended on by every Finance ViewModel, just scoped to Finance instead of
/// the whole app.
final class FinanceChangeSignal extends ChangeNotifier {
  /// Called by [TransactionsViewModel] after any transaction mutation that
  /// successfully committed (create, update, delete, restore, transfer).
  void notifyChanged() => notifyListeners();
}
