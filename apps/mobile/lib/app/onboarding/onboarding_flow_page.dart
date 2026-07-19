import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The application's first-run experience (Milestone 6 Part B — TIS §1
/// "First-Run Experience"): three concise screens (Welcome, Feature
/// overview, Get Started) shown at most once per install.
///
/// Every exit path — Skip, Start Fresh, or Demo Mode — marks onboarding
/// completed via the app layer's [OnboardingStatusStore] before this page
/// is popped; this widget itself only calls the callbacks it's given.
final class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({
    super.key,
    required this.onStartFresh,
    required this.onEnableDemoMode,
  });

  /// Invoked for both "Skip" and "Start Fresh" — both mean "begin using the
  /// app with my own (currently empty) data."
  final Future<void> Function() onStartFresh;

  /// Invoked for "Try Demo Mode" — enables Demo Mode before entering the
  /// app.
  final Future<void> Function() onEnableDemoMode;

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final _pageController = PageController();
  var _page = 0;
  var _busy = false;

  static const _pageCount = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await action();
  }

  void _next() {
    _pageController.nextPage(
      duration: AppMotion.durationOrZero(context, AppMotion.page),
      curve: AppMotion.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Visibility(
                  visible: !isLastPage,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    onPressed: _busy ? null : () => _finish(widget.onStartFresh),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _page = page),
                children: const [
                  _WelcomePage(),
                  _FeatureOverviewPage(),
                  _GetStartedPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _page
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (!isLastPage)
                    FilledButton(
                      onPressed: _next,
                      child: const Text('Next'),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _finish(widget.onEnableDemoMode),
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Explore with Demo Mode'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _busy ? null : () => _finish(widget.onStartFresh),
                            child: const Text('Start Fresh'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize_outlined, size: 96, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Welcome to Personal OS',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your personal operating system for finances, tasks, habits, and more — '
            'all in one place.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureOverviewPage extends StatelessWidget {
  const _FeatureOverviewPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const features = [
      (Icons.account_balance_wallet_outlined, 'Finance',
          'Track accounts, income, expenses, and transfers.'),
      (Icons.check_circle_outline, 'More modules on the way',
          'Tasks, Habits, Goals, and more are coming soon.'),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you can do',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final (icon, title, description) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GetStartedPage extends StatelessWidget {
  const _GetStartedPage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rocket_launch_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'How would you like to start?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Try Demo Mode to explore with realistic sample data, or start fresh '
            'with your own — you can switch anytime from Settings.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
