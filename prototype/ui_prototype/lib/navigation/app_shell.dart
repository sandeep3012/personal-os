import 'package:flutter/material.dart';

import '../screens/calendar/calendar_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/finance/accounts_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/tasks/tasks_screen.dart';

/// DOC-033 §10.3 / DOC-034 Part L — the approved 5-destination bottom nav:
/// Home, Finance, Tasks, Calendar, More. Tab state is preserved via
/// [IndexedStack], mirroring the production `StatefulShellRoute` shape —
/// UI-only here, no go_router, no DI.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    AccountsScreen(),
    TasksScreen(),
    CalendarScreen(),
    MoreScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet),
      label: 'Finance',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle),
      label: 'Tasks',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Calendar',
    ),
    NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _destinations,
      ),
    );
  }
}
