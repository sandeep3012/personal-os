import 'package:feature_finance/finance.dart';
import 'package:flutter/foundation.dart';
import 'package:personal_os/app/demo/demo_finance_seed_data.dart';
import 'package:personal_os/app/demo/switchable_finance_storage.dart';

/// Owns whether the app is currently showing sample data instead of the
/// user's real Finance data, and performs the swap (Milestone 6 Part A).
///
/// This is the one place that knows about "demo vs. real" — every
/// repository, use case, and ViewModel resolves
/// [SwitchableFinanceDatabaseExecutor]/[SwitchableFinanceTransactionRunner]
/// (registered once, never replaced) and stays completely unaware that a
/// swap ever happens. Presentation code never branches on `isDemoMode`
/// except to decide what to *show* (the [DemoModeBanner], the Settings
/// section) — it never touches persistence directly.
///
/// [generation] increments on every enable/exit/reset; the app root uses it
/// as a [ValueKey] to force a full remount of the shell (every already-open
/// page's ViewModel is a DI factory — see `FinanceModule` — so a remount is
/// sufficient to make every page reload against the newly active data
/// source, without each page needing to listen for a demo-mode change
/// itself).
final class DemoModeController extends ChangeNotifier {
  DemoModeController({
    required SwitchableFinanceDatabaseExecutor executor,
    required SwitchableFinanceTransactionRunner runner,
    required IFinanceDatabaseExecutor realExecutor,
    required IFinanceTransactionRunner realRunner,
    required this.workspaceId,
  })  : _executor = executor,
        _runner = runner,
        _realExecutor = realExecutor,
        _realRunner = realRunner;

  final SwitchableFinanceDatabaseExecutor _executor;
  final SwitchableFinanceTransactionRunner _runner;
  final IFinanceDatabaseExecutor _realExecutor;
  final IFinanceTransactionRunner _realRunner;
  final String workspaceId;

  bool _isDemoMode = false;
  bool get isDemoMode => _isDemoMode;

  var _generation = 0;

  /// Bumped on every mode change — see class doc for why the app root keys
  /// off this to force a full remount.
  int get generation => _generation;

  /// Switches to a freshly seeded in-memory demo dataset. The user's real
  /// (file-backed) data is left completely untouched — demo writes only
  /// ever land in the fresh in-memory store created here.
  Future<void> enableDemoMode() async {
    final demoExecutor = InMemoryFinanceDatabaseExecutor();
    await DemoFinanceSeedData.seed(demoExecutor, workspaceId: workspaceId);
    _executor.switchTo(demoExecutor);
    _runner.switchTo(InMemoryFinanceTransactionRunner(demoExecutor));
    _isDemoMode = true;
    _generation++;
    notifyListeners();
  }

  /// Switches back to the user's real (file-backed) data. Whatever was in
  /// the demo dataset is discarded — it was never persisted anywhere.
  Future<void> exitDemoMode() async {
    _executor.switchTo(_realExecutor);
    _runner.switchTo(_realRunner);
    _isDemoMode = false;
    _generation++;
    notifyListeners();
  }

  /// Discards the current demo dataset and reseeds a fresh one. A no-op if
  /// not currently in Demo Mode.
  Future<void> resetDemoData() async {
    if (!_isDemoMode) return;
    await enableDemoMode();
  }
}
