import 'dart:async';

import 'package:feature_finance/finance.dart';
import 'package:feature_sample/sample.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_os/app/bootstrap/app_bootstrap.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/home/home_dashboard_page.dart';
import 'package:personal_os/app/navigation/app_router.dart';
import 'package:personal_os/app/onboarding/onboarding_flow_page.dart';
import 'package:personal_os/app/onboarding/onboarding_status_store.dart';
import 'package:personal_os/app/settings/settings_page.dart';
import 'package:personal_os/app/shell/shell_branches.dart';
import 'package:personal_os/app/theme/app_theme.dart';

/// The root widget of Personal OS.
///
/// Receives a fully booted [AppBootstrap] and constructs the router and
/// Material 3 app. Listens to [AppLifecycleState.detached] to trigger a
/// graceful runtime shutdown.
///
/// ## Feature route wiring
///
/// Feature packages register [RouteDefinition]s in [RouteRegistry] during
/// boot. The app layer (here) maps each feature's route constants to a
/// [GoRoute] with a concrete Flutter builder, then passes them to
/// [AppRouter.create] via `financeRoutes`/`otherTopLevelRoutes`.
///
/// This is the approved app-layer bridge pattern (ADR-003 §4). Feature
/// packages never import go_router; they navigate via [NavigationService]
/// (full implementation: Sprint 8).
///
/// ## AppShell (Milestone 1A)
///
/// Home is the application's true root. [AppRouter.create] wraps Home,
/// Finance, and Settings in one `StatefulShellRoute` (persistent bottom
/// nav / rail — see [AppShell]); Finance's existing pages are unchanged and
/// now live inside the shell's Finance branch instead of as flat top-level
/// routes. The platform diagnostics screen remains a plain top-level route
/// at [AppRouter.diagnosticsPath], reachable via the "Diagnostics" entry in
/// [FinanceNavigationDrawer], shown on every Finance page.
class PersonalOsApp extends StatefulWidget {
  const PersonalOsApp({super.key, required this.bootstrap});

  final AppBootstrap bootstrap;

  @override
  State<PersonalOsApp> createState() => _PersonalOsAppState();
}

class _PersonalOsAppState extends State<PersonalOsApp>
    with WidgetsBindingObserver {
  late final GoRouter _router;
  late final DemoModeController _demoModeController;

  static const String _onboardingPath = '/onboarding';
  static const String _onboardingName = 'onboarding';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _demoModeController = widget.bootstrap.registry.get<DemoModeController>();

    // Build feature GoRoute lists from each feature's route constants +
    // pages. The DI registry resolves feature services needed by page
    // constructors. Finance's routes go inside the shell's Finance branch;
    // Sample's stays a plain top-level route (Milestone 1A does not touch
    // Sample).
    _router = AppRouter.create(
      config: widget.bootstrap.config,
      homeBuilder: _buildHome,
      settingsBuilder: _buildSettings,
      demoModeController: _demoModeController,
      financeRoutes: _buildFinanceRoutes(),
      otherTopLevelRoutes: _buildOtherTopLevelRoutes(),
      initialLocation:
          widget.bootstrap.needsOnboarding ? _onboardingPath : ShellBranches.homePath,
    );
  }

  /// Builds the Home branch's landing screen — the real [HomeDashboardPage]
  /// (Milestone 5 Part B), replacing the Milestone 1A placeholder. Reuses
  /// the same [FinanceNavCallbacks] composition point as every Finance page
  /// (ADR-003) so Home's Quick Actions/module card navigate identically to
  /// Finance's own drawer.
  Widget _buildHome(BuildContext context, GoRouterState state) =>
      HomeDashboardPage(
        financeViewModel: widget.bootstrap.registry.get<FinanceHomeViewModel>(),
        onOpenFinance: () => context.goNamed(FinanceRoutes.root.name),
        onOpenAccounts: () => context.goNamed(FinanceRoutes.accounts.name),
        onOpenTransactions: () =>
            context.goNamed(FinanceRoutes.transactions.name),
      );

  /// Builds the Settings branch's landing screen — the real [SettingsPage]
  /// (Milestone 6 Part E), replacing the Milestone 1A placeholder.
  Widget _buildSettings(BuildContext context, GoRouterState state) =>
      SettingsPage(demoModeController: _demoModeController);

  /// Builds the first-run onboarding route (Milestone 6 Part B) — a
  /// top-level route outside the shell, exactly like [AppRouter.diagnosticsPath].
  /// Every exit path marks onboarding completed via
  /// [OnboardingStatusStore] before entering the app's Home branch.
  GoRoute _buildOnboardingRoute() => GoRoute(
        path: _onboardingPath,
        name: _onboardingName,
        builder: (context, state) => OnboardingFlowPage(
          onStartFresh: () => _finishOnboarding(context),
          onEnableDemoMode: () async {
            await _demoModeController.enableDemoMode();
            if (!context.mounted) return;
            await _finishOnboarding(context);
          },
        ),
      );

  Future<void> _finishOnboarding(BuildContext context) async {
    await widget.bootstrap.registry.get<OnboardingStatusStore>().markCompleted();
    if (!context.mounted) return;
    context.goNamed(ShellBranches.homeName);
  }

  /// Navigation callbacks shared by every Finance page's drawer (and, on
  /// the Dashboard, its Quick Actions) — the single app-layer composition
  /// point for Finance-internal navigation (ADR-003).
  FinanceNavCallbacks _financeNavCallbacks(BuildContext context) =>
      FinanceNavCallbacks(
        onOpenDashboard: () => context.goNamed(FinanceRoutes.root.name),
        onOpenAccounts: () => context.goNamed(FinanceRoutes.accounts.name),
        onOpenTransactions: () =>
            context.goNamed(FinanceRoutes.transactions.name),
        onOpenCategories: () => context.goNamed(FinanceRoutes.categories.name),
        onOpenDiagnostics: () => context.goNamed(AppRouter.diagnosticsName),
      );

  /// Routes that stay outside the shell: Sample (Milestone 1A) and
  /// Onboarding (Milestone 6 Part B) — neither is a primary navigation
  /// destination.
  ///
  /// Each feature's public barrel exports:
  ///   - Route constants (e.g. [SampleRoutes.root]) — path + name
  ///   - Page widget (e.g. [SamplePage]) — Flutter builder
  ///   - Services (e.g. [SampleService]) — resolved from DI
  List<RouteBase> _buildOtherTopLevelRoutes() => [
        GoRoute(
          path: SampleRoutes.root.path,
          name: SampleRoutes.root.name,
          builder: (context, state) => SamplePage(
            service: widget.bootstrap.registry.get<SampleService>(),
          ),
        ),
        _buildOnboardingRoute(),
      ];

  /// Assembles the go_router [GoRoute] entries for Finance's existing
  /// pages, placed inside the shell's Finance branch by
  /// [ShellBranches.build]. Unchanged from before Milestone 1A — same
  /// paths, names, and builders; only their position in the route tree
  /// moved.
  List<RouteBase> _buildFinanceRoutes() => [
        GoRoute(
          path: FinanceRoutes.accounts.path,
          name: FinanceRoutes.accounts.name,
          builder: (context, state) => AccountsPage(
            viewModel: widget.bootstrap.registry.get<AccountsViewModel>(),
            navCallbacks: _financeNavCallbacks(context),
          ),
        ),
        GoRoute(
          path: FinanceRoutes.transactions.path,
          name: FinanceRoutes.transactions.name,
          builder: (context, state) => TransactionsPage(
            viewModel: widget.bootstrap.registry.get<TransactionsViewModel>(),
            navCallbacks: _financeNavCallbacks(context),
          ),
        ),
        GoRoute(
          path: FinanceRoutes.root.path,
          name: FinanceRoutes.root.name,
          builder: (context, state) => FinanceHomePage(
            viewModel: widget.bootstrap.registry.get<FinanceHomeViewModel>(),
            navCallbacks: _financeNavCallbacks(context),
          ),
        ),
        GoRoute(
          path: FinanceRoutes.categories.path,
          name: FinanceRoutes.categories.name,
          builder: (context, state) => CategoriesPage(
            viewModel: widget.bootstrap.registry.get<CategoriesViewModel>(),
            navCallbacks: _financeNavCallbacks(context),
          ),
        ),
      ];

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(widget.bootstrap.shutdown());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _demoModeController,
      builder: (context, _) => MaterialApp.router(
        // Every already-open page's ViewModel is a DI *factory* (see
        // FinanceModule) resolved once when that page's State first builds —
        // switching Finance's active data source (real ⇄ demo) doesn't
        // retroactively refresh a ViewModel a page already holds, and
        // go_router's `StatefulShellRoute.indexedStack` keeps every branch
        // mounted simultaneously. Keying the whole app on
        // [DemoModeController.generation] forces Flutter to tear down and
        // rebuild the entire shell on every enable/exit/reset, so every page
        // resolves a fresh ViewModel against the newly active source —
        // without any page needing to listen for a demo-mode change itself.
        key: ValueKey(_demoModeController.generation),
        title: 'Personal OS',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}

/// Shown when [AppBootstrap.boot] throws an exception.
///
/// Displays the error message and a retry button that re-runs the bootstrap
/// sequence.
class BootFailureApp extends StatelessWidget {
  const BootFailureApp({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal OS',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Platform failed to initialize',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () async => onRetry(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
