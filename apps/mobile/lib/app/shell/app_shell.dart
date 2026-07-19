import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:personal_os/app/shell/shell_branches.dart';

/// The persistent application chrome wrapping every shell branch (Home,
/// Finance, Settings — TIS §4 "AppShell Implementation").
///
/// Built on go_router's `StatefulShellRoute.indexedStack`: each branch keeps
/// its own independent [Navigator] (state/scroll position preserved when
/// switching tabs), and [navigationShell] is the `IndexedStack` of all
/// branches' current pages.
///
/// Adaptive navigation (TIS §4 / VPS §1.7 window-size classes): a bottom
/// `NavigationBar` below 600dp width, a `NavigationRail` at or above it
/// (labeled once width reaches 840dp, per M3 window-size-class guidance).
///
/// Back-button behavior (Architecture Proposal §2.3 / TIS §4): pressing
/// back on any branch other than Home, once that branch's own navigator has
/// nothing left to pop, returns to the Home branch instead of exiting the
/// app. Only Home's own root allows the default pop-to-exit behavior. This
/// is the fix for "pressing Android Back from any Finance screen closes the
/// application."
final class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    required this.demoModeController,
  });

  /// The active branch stack, supplied by [StatefulShellRoute.indexedStack]'s
  /// builder.
  final StatefulNavigationShell navigationShell;

  /// Drives the persistent [DemoModeBanner] shown above every branch while
  /// Demo Mode is active (Milestone 6 Part A — "clearly indicated throughout
  /// the UI").
  final DemoModeController demoModeController;

  static const int _homeBranchIndex = 0;

  Widget _demoModeBanner() => ListenableBuilder(
        listenable: demoModeController,
        builder: (context, _) => DemoModeBanner(
          moduleNames: demoModeController.isDemoMode ? const ['Finance'] : const [],
        ),
      );

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Tapping the already-active destination returns to that branch's
      // own root (go_router's documented StatefulShellRoute pattern) rather
      // than leaving a stale pushed sub-route in place.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 600;
    const destinations = ShellBranches.destinations;

    return PopScope(
      canPop: navigationShell.currentIndex == _homeBranchIndex,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        navigationShell.goBranch(_homeBranchIndex);
      },
      child: useRail
          ? _RailLayout(
              navigationShell: navigationShell,
              destinations: destinations,
              labeled: width >= 840,
              onDestinationSelected: _onDestinationSelected,
              banner: _demoModeBanner(),
            )
          : _BottomNavLayout(
              navigationShell: navigationShell,
              destinations: destinations,
              onDestinationSelected: _onDestinationSelected,
              banner: _demoModeBanner(),
            ),
    );
  }
}

class _BottomNavLayout extends StatelessWidget {
  const _BottomNavLayout({
    required this.navigationShell,
    required this.destinations,
    required this.onDestinationSelected,
    required this.banner,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          banner,
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _RailLayout extends StatelessWidget {
  const _RailLayout({
    required this.navigationShell,
    required this.destinations,
    required this.labeled,
    required this.onDestinationSelected,
    required this.banner,
  });

  final StatefulNavigationShell navigationShell;
  final List<ShellDestination> destinations;
  final bool labeled;
  final ValueChanged<int> onDestinationSelected;
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          banner,
          Expanded(
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: labeled
                      ? NavigationRailLabelType.all
                      : NavigationRailLabelType.none,
                  destinations: [
                    for (final destination in destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
