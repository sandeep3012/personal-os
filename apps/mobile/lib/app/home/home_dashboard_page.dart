import 'package:application/application.dart' show AsyncState;
import 'package:design_system/design_system.dart';
import 'package:feature_assets/assets.dart' show AssetsDashboardSummary, AssetsHomeViewModel;
import 'package:feature_calendar/calendar.dart' show CalendarDashboardSummary, CalendarHomeViewModel;
import 'package:feature_documents/documents.dart' show DocumentsDashboardSummary, DocumentsHomeViewModel;
import 'package:feature_finance/finance.dart';
import 'package:feature_goals/goals.dart' show GoalsDashboardSummary, GoalsHomeViewModel;
import 'package:feature_habits/habits.dart' show HabitsDashboardSummary, HabitsHomeViewModel;
import 'package:feature_notes/notes.dart' show NotesDashboardSummary, NotesHomeViewModel;
import 'package:feature_tasks/tasks.dart' show TasksDashboardSummary, TasksHomeViewModel;
import 'package:flutter/material.dart';

/// The application's true landing screen (Milestone 5 Part B — TIS §1
/// Milestone 2 "Home Dashboard"; extended with Tasks in Milestone 7;
/// extended with Habits thereafter).
///
/// Built entirely from `package:design_system` components. Finance, Tasks,
/// Habits, Goals, Notes, Calendar, Assets, and Documents are the only
/// modules with real data today; every other module (AI) renders a static,
/// visually polished placeholder [SummaryCard] — no fake repositories,
/// ViewModels, or business logic are invented for them (Milestone 5 Part B
/// scope).
///
/// Each module summary renders through [ModuleCard], which isolates its own
/// loading/error state from the rest of the page (TIS §5 "Loading / Error
/// isolation") — a failed Finance, Tasks, or Habits load never blanks the
/// other modules' cards or the placeholder sections below.
final class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    super.key,
    required this.financeViewModel,
    required this.tasksViewModel,
    required this.habitsViewModel,
    required this.goalsViewModel,
    required this.notesViewModel,
    required this.calendarViewModel,
    required this.assetsViewModel,
    required this.documentsViewModel,
    this.onOpenFinance,
    this.onOpenAccounts,
    this.onOpenTransactions,
    this.onOpenTasks,
    this.onOpenHabits,
    this.onOpenGoals,
    this.onOpenNotes,
    this.onOpenCalendar,
    this.onOpenAssets,
    this.onOpenDocuments,
  });

  final FinanceHomeViewModel financeViewModel;
  final TasksHomeViewModel tasksViewModel;
  final HabitsHomeViewModel habitsViewModel;
  final GoalsHomeViewModel goalsViewModel;
  final NotesHomeViewModel notesViewModel;
  final CalendarHomeViewModel calendarViewModel;
  final AssetsHomeViewModel assetsViewModel;
  final DocumentsHomeViewModel documentsViewModel;
  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenTransactions;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenHabits;
  final VoidCallback? onOpenGoals;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenAssets;
  final VoidCallback? onOpenDocuments;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.financeViewModel.load();
    widget.tasksViewModel.load();
    widget.habitsViewModel.load();
    widget.goalsViewModel.load();
    widget.notesViewModel.load();
    widget.calendarViewModel.load();
    widget.assetsViewModel.load();
    widget.documentsViewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final windowClass = AppBreakpoints.of(context);
    final placeholderColumns = switch (windowClass) {
      AppWindowSizeClass.compact => 1,
      AppWindowSizeClass.medium => 2,
      AppWindowSizeClass.expanded => 3,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListenableBuilder(
        listenable: Listenable.merge([
          widget.financeViewModel,
          widget.tasksViewModel,
          widget.habitsViewModel,
          widget.goalsViewModel,
          widget.notesViewModel,
          widget.calendarViewModel,
          widget.assetsViewModel,
          widget.documentsViewModel,
        ]),
        builder: (context, _) => RefreshIndicator(
          onRefresh: () => Future.wait([
            widget.financeViewModel.refresh(),
            widget.tasksViewModel.refresh(),
            widget.habitsViewModel.refresh(),
            widget.goalsViewModel.refresh(),
            widget.notesViewModel.refresh(),
            widget.calendarViewModel.refresh(),
            widget.assetsViewModel.refresh(),
            widget.documentsViewModel.refresh(),
          ]),
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              _entrance(0, const _WelcomeHeader()),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                1,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _FinanceModuleCard(
                    state: widget.financeViewModel.state,
                    onTap: widget.onOpenFinance,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _TasksModuleCard(
                    state: widget.tasksViewModel.state,
                    onTap: widget.onOpenTasks,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _HabitsModuleCard(
                    state: widget.habitsViewModel.state,
                    onTap: widget.onOpenHabits,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _GoalsModuleCard(
                    state: widget.goalsViewModel.state,
                    onTap: widget.onOpenGoals,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _NotesModuleCard(
                    state: widget.notesViewModel.state,
                    onTap: widget.onOpenNotes,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _CalendarModuleCard(
                    state: widget.calendarViewModel.state,
                    onTap: widget.onOpenCalendar,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _AssetsModuleCard(
                    state: widget.assetsViewModel.state,
                    onTap: widget.onOpenAssets,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _entrance(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _DocumentsModuleCard(
                    state: widget.documentsViewModel.state,
                    onTap: widget.onOpenDocuments,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _entrance(
                3,
                _RecentTransactionsSection(
                  data: widget.financeViewModel.state.dataOrNull,
                  onSeeAll: widget.onOpenTransactions,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _entrance(
                4,
                _AccountOverviewSection(
                  data: widget.financeViewModel.state.dataOrNull,
                  onSeeAll: widget.onOpenAccounts,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _entrance(
                5,
                _QuickActionsSection(
                  onOpenFinance: widget.onOpenFinance,
                  onOpenAccounts: widget.onOpenAccounts,
                  onOpenTransactions: widget.onOpenTransactions,
                  onOpenTasks: widget.onOpenTasks,
                  onOpenHabits: widget.onOpenHabits,
                  onOpenGoals: widget.onOpenGoals,
                  onOpenNotes: widget.onOpenNotes,
                  onOpenCalendar: widget.onOpenCalendar,
                  onOpenAssets: widget.onOpenAssets,
                  onOpenDocuments: widget.onOpenDocuments,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _entrance(
                6,
                const SectionHeader(title: 'More modules'),
              ),
              _entrance(
                7,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _PlaceholderModuleGrid(columns: placeholderColumns),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Wraps [child] in a subtle, once-only entrance animation, staggered by
  /// [index] (VPS "subtle entrance animations on summary/module cards").
  Widget _entrance(int index, Widget child) => _EntranceFade(index: index, child: child);
}

/// A once-only fade+slide-up entrance, staggered by [index] and respecting
/// reduced-motion (AppMotion is the only source of durations/curves — TIS
/// §11).
final class _EntranceFade extends StatefulWidget {
  const _EntranceFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<_EntranceFade> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    // Reads the platform dispatcher directly rather than `MediaQuery.of`/
    // `.maybeOf` — those establish an InheritedWidget dependency, which
    // isn't allowed this early (`initState` runs before the element has
    // finished mounting into the tree). `AppMotion.durationOrZero` in
    // `build` below still re-checks reduced motion via `MediaQuery` on every
    // rebuild, so this initState-only read only needs to decide whether to
    // skip the staggered delay, not to be perfectly reactive to later
    // changes.
    final reduceMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    if (reduceMotion) {
      _visible = true;
      return;
    }
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.durationOrZero(context, AppMotion.page);
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: duration,
      curve: AppMotion.standardCurve,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: duration,
        curve: AppMotion.standardCurve,
        child: widget.child,
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final greeting = _greetingFor(DateTime.now().hour);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Here's your overview",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _FinanceModuleCard extends StatelessWidget {
  const _FinanceModuleCard({required this.state, this.onTap});

  final AsyncState<FinanceDashboardData> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('finance') ?? theme.colorScheme.primary;

    return ModuleCard<FinanceDashboardData>(
      icon: Icons.account_balance_wallet_outlined,
      accentColor: accent,
      title: 'Finance',
      state: state,
      loadingHeight: 120,
      onTap: onTap,
      semanticLabel: 'Finance summary',
      contentBuilder: (context, data) => _FinanceCardBody(data: data),
    );
  }
}

class _FinanceCardBody extends StatelessWidget {
  const _FinanceCardBody({required this.data});

  final FinanceDashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = data.totalBalanceByCurrency.entries.toList();
    final primaryBalance = entries.isEmpty ? null : entries.first;

    // Expense-to-income ratio for this month, clamped for display — a
    // simple presentation-layer derivation of two already-fetched totals,
    // not a new business rule.
    final incomeAmount = data.totalIncome.amount.toDouble();
    final expenseAmount = data.totalExpenses.amount.toDouble();
    final spendRatio = incomeAmount <= 0 ? 0.0 : (expenseAmount / incomeAmount).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Balance', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        if (primaryBalance != null)
          MoneyText(
            amount: primaryBalance.value.amount,
            currencyCode: primaryBalance.key,
            variant: MoneyTextVariant.display,
          )
        else
          Text('No accounts yet', style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MiniStat(
                icon: Icons.arrow_upward,
                label: 'Income',
                money: MoneyText(
                  amount: data.totalIncome.amount,
                  currencyCode: data.totalIncome.currency.value,
                  semantic: MoneySemantic.positive,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MiniStat(
                icon: Icons.arrow_downward,
                label: 'Expenses',
                money: MoneyText(
                  amount: data.totalExpenses.amount,
                  currencyCode: data.totalExpenses.currency.value,
                  semantic: MoneySemantic.negative,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Monthly spending', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        ProportionBar(
          value: spendRatio,
          semanticLabel: 'Spent ${(spendRatio * 100).round()} percent of income this month',
        ),
      ],
    );
  }
}

class _TasksModuleCard extends StatelessWidget {
  const _TasksModuleCard({required this.state, this.onTap});

  final AsyncState<TasksDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('tasks') ?? theme.colorScheme.primary;

    return ModuleCard<TasksDashboardSummary>(
      icon: Icons.check_circle_outline,
      accentColor: accent,
      title: 'Tasks',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Tasks summary',
      contentBuilder: (context, data) => _TasksCardBody(data: data),
    );
  }
}

class _TasksCardBody extends StatelessWidget {
  const _TasksCardBody({required this.data});

  final TasksDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.pending_actions_outlined,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.task_alt_outlined,
            label: 'Completed today',
            value: data.completedTodayCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _HabitsModuleCard extends StatelessWidget {
  const _HabitsModuleCard({required this.state, this.onTap});

  final AsyncState<HabitsDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('habits') ?? theme.colorScheme.primary;

    return ModuleCard<HabitsDashboardSummary>(
      icon: Icons.local_fire_department_outlined,
      accentColor: accent,
      title: 'Habits',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Habits summary',
      contentBuilder: (context, data) => _HabitsCardBody(data: data),
    );
  }
}

class _HabitsCardBody extends StatelessWidget {
  const _HabitsCardBody({required this.data});

  final HabitsDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.repeat,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_outlined,
            label: 'Completed today',
            value: data.completedTodayCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _GoalsModuleCard extends StatelessWidget {
  const _GoalsModuleCard({required this.state, this.onTap});

  final AsyncState<GoalsDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('goals') ?? theme.colorScheme.primary;

    return ModuleCard<GoalsDashboardSummary>(
      icon: Icons.flag_outlined,
      accentColor: accent,
      title: 'Goals',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Goals summary',
      contentBuilder: (context, data) => _GoalsCardBody(data: data),
    );
  }
}

class _GoalsCardBody extends StatelessWidget {
  const _GoalsCardBody({required this.data});

  final GoalsDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.flag_outlined,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.emoji_events_outlined,
            label: 'Completed',
            value: data.completedCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _NotesModuleCard extends StatelessWidget {
  const _NotesModuleCard({required this.state, this.onTap});

  final AsyncState<NotesDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('notes') ?? theme.colorScheme.primary;

    return ModuleCard<NotesDashboardSummary>(
      icon: Icons.note_outlined,
      accentColor: accent,
      title: 'Notes',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Notes summary',
      contentBuilder: (context, data) => _NotesCardBody(data: data),
    );
  }
}

class _NotesCardBody extends StatelessWidget {
  const _NotesCardBody({required this.data});

  final NotesDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.note_outlined,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.archive_outlined,
            label: 'Archived',
            value: data.archivedCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _CalendarModuleCard extends StatelessWidget {
  const _CalendarModuleCard({required this.state, this.onTap});

  final AsyncState<CalendarDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('calendar') ?? theme.colorScheme.primary;

    return ModuleCard<CalendarDashboardSummary>(
      icon: Icons.calendar_today_outlined,
      accentColor: accent,
      title: 'Calendar',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Calendar summary',
      contentBuilder: (context, data) => _CalendarCardBody(data: data),
    );
  }
}

class _CalendarCardBody extends StatelessWidget {
  const _CalendarCardBody({required this.data});

  final CalendarDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.event_outlined,
            label: 'Upcoming',
            value: data.upcomingCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.archive_outlined,
            label: 'Archived',
            value: data.archivedCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _AssetsModuleCard extends StatelessWidget {
  const _AssetsModuleCard({required this.state, this.onTap});

  final AsyncState<AssetsDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('assets') ?? theme.colorScheme.primary;

    return ModuleCard<AssetsDashboardSummary>(
      icon: Icons.inventory_2_outlined,
      accentColor: accent,
      title: 'Assets',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Assets summary',
      contentBuilder: (context, data) => _AssetsCardBody(data: data),
    );
  }
}

class _AssetsCardBody extends StatelessWidget {
  const _AssetsCardBody({required this.data});

  final AssetsDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.inventory_2_outlined,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            icon: Icons.payments_outlined,
            label: 'Total value',
            value: data.totalValue,
          ),
        ),
      ],
    );
  }
}

class _DocumentsModuleCard extends StatelessWidget {
  const _DocumentsModuleCard({required this.state, this.onTap});

  final AsyncState<DocumentsDashboardSummary> state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();
    final accent = semanticColors?.moduleAccent('documents') ?? theme.colorScheme.primary;

    return ModuleCard<DocumentsDashboardSummary>(
      icon: Icons.description_outlined,
      accentColor: accent,
      title: 'Documents',
      state: state,
      loadingHeight: 96,
      onTap: onTap,
      semanticLabel: 'Documents summary',
      contentBuilder: (context, data) => _DocumentsCardBody(data: data),
    );
  }
}

class _DocumentsCardBody extends StatelessWidget {
  const _DocumentsCardBody({required this.data});

  final DocumentsDashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.description_outlined,
            label: 'Active',
            value: data.activeCount.toDouble(),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.money,
  });

  final IconData icon;
  final String label;
  final Widget money;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSizes.inline),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: theme.textTheme.labelMedium),
          ],
        ),
        money,
      ],
    );
  }
}

class _RecentTransactionsSection extends StatelessWidget {
  const _RecentTransactionsSection({required this.data, this.onSeeAll});

  final FinanceDashboardData? data;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final transactions = data?.recentTransactions ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Recent Transactions', onSeeAll: onSeeAll),
        if (data == null)
          const SizedBox.shrink()
        else if (transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('No recent transactions'),
          )
        else
          for (final txn in transactions.take(5))
            TransactionTile(
              // The tile type is derived inline (rather than via a typed
              // helper taking a `Transaction` parameter) since that domain
              // type isn't part of feature_finance's public barrel —
              // AccountTile/TransactionTile themselves only ever take
              // primitive values for the same reason.
              type: txn.transferCounterpartId != null
                  ? TransactionTileType.transfer
                  : switch (txn.type.name) {
                      'expense' => TransactionTileType.expense,
                      'income' => TransactionTileType.income,
                      _ => TransactionTileType.transfer,
                    },
              title: txn.payee?.value ?? txn.type.name,
              subtitle: txn.note ?? txn.type.name,
              amountText: MoneyText.format(txn.amount.amount, txn.amount.currency.value),
            ),
      ],
    );
  }
}

class _AccountOverviewSection extends StatelessWidget {
  const _AccountOverviewSection({required this.data, this.onSeeAll});

  final FinanceDashboardData? data;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final accounts = data?.accounts ?? const <AccountListItem>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Accounts', onSeeAll: onSeeAll),
        if (data == null)
          const SizedBox.shrink()
        else if (accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('Add an account to see it here'),
          )
        else
          for (final item in accounts.take(3))
            AccountTile(
              icon: Icons.account_balance_wallet_outlined,
              name: item.account.name,
              subtitle: item.account.type.name,
              balanceText: MoneyText.format(item.balance.amount, item.balance.currency.value),
            ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    this.onOpenFinance,
    this.onOpenAccounts,
    this.onOpenTransactions,
    this.onOpenTasks,
    this.onOpenHabits,
    this.onOpenGoals,
    this.onOpenNotes,
    this.onOpenCalendar,
    this.onOpenAssets,
    this.onOpenDocuments,
  });

  final VoidCallback? onOpenFinance;
  final VoidCallback? onOpenAccounts;
  final VoidCallback? onOpenTransactions;
  final VoidCallback? onOpenTasks;
  final VoidCallback? onOpenHabits;
  final VoidCallback? onOpenGoals;
  final VoidCallback? onOpenNotes;
  final VoidCallback? onOpenCalendar;
  final VoidCallback? onOpenAssets;
  final VoidCallback? onOpenDocuments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (onOpenFinance != null)
                QuickActionButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Open Finance',
                  onTap: onOpenFinance!,
                ),
              if (onOpenAccounts != null)
                QuickActionButton(
                  icon: Icons.account_balance_outlined,
                  label: 'View Accounts',
                  onTap: onOpenAccounts!,
                ),
              if (onOpenTransactions != null)
                QuickActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'View Transactions',
                  onTap: onOpenTransactions!,
                ),
              if (onOpenTasks != null)
                QuickActionButton(
                  icon: Icons.add_task_outlined,
                  label: 'Add Task',
                  onTap: onOpenTasks!,
                ),
              if (onOpenHabits != null)
                QuickActionButton(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Log Habit',
                  onTap: onOpenHabits!,
                ),
              if (onOpenGoals != null)
                QuickActionButton(
                  icon: Icons.flag_outlined,
                  label: 'Add Goal',
                  onTap: onOpenGoals!,
                ),
              if (onOpenNotes != null)
                QuickActionButton(
                  icon: Icons.note_add_outlined,
                  label: 'Add Note',
                  onTap: onOpenNotes!,
                ),
              if (onOpenCalendar != null)
                QuickActionButton(
                  icon: Icons.event_outlined,
                  label: 'Add Event',
                  onTap: onOpenCalendar!,
                ),
              if (onOpenAssets != null)
                QuickActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Add Asset',
                  onTap: onOpenAssets!,
                ),
              if (onOpenDocuments != null)
                QuickActionButton(
                  icon: Icons.description_outlined,
                  label: 'Add Document',
                  onTap: onOpenDocuments!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Static, visually-polished placeholders for every module without real
/// data yet (Milestone 5 Part B — explicitly no fake repositories/
/// ViewModels/business logic).
class _PlaceholderModuleGrid extends StatelessWidget {
  const _PlaceholderModuleGrid({required this.columns});

  final int columns;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors = theme.extension<AppSemanticColors>();

    Color accentFor(String moduleId) =>
        semanticColors?.moduleAccent(moduleId) ?? theme.colorScheme.primary;

    final cards = <Widget>[
      SummaryCard(
        icon: Icons.auto_awesome_outlined,
        accentColor: accentFor('ai'),
        title: 'AI Assistant',
        body: const _ComingSoonBody(message: 'Your AI assistant is coming soon'),
      ),
    ];

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: columns == 1 ? 2.2 : 1.4,
      children: cards,
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}
