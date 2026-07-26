import 'package:flutter/material.dart';

import '../../design/theme/app_theme.dart';
import '../../design/tokens/app_spacing.dart';
import '../../navigation/app_shell.dart';

/// DOC-034 Part A §2 — Welcome → Feature overview → Get Started.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  void _finish() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: _page < 2
                    ? TextButton(onPressed: _finish, child: const Text('Skip'))
                    : const SizedBox(height: 48),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _WelcomePage(),
                  _FeatureOverviewPage(),
                  _GetStartedPage(onStartFresh: _finish, onDemoMode: _finish),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => _Dot(active: i == _page)),
              ),
            ),
            if (_page < 2)
              Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xl,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _controller.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                    ),
                    child: const Text('Next'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? scheme.primary : scheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Text('⌂', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Welcome to\nPersonal OS', textAlign: TextAlign.center, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            'One calm place for your money, tasks, habits, and time.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
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
    final semantic = AppTheme.semanticColors(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    Widget iconChip(String emoji, String label, Color color) => Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: textTheme.labelLarge),
          ],
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              iconChip('💰', 'Finance', semantic.moduleAccent('finance')),
              iconChip('✓', 'Tasks', semantic.moduleAccent('tasks')),
              iconChip('📅', 'Calendar', semantic.moduleAccent('calendar')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Everything you track, in one app that stays out of your way.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _GetStartedPage extends StatelessWidget {
  const _GetStartedPage({required this.onStartFresh, required this.onDemoMode});
  final VoidCallback onStartFresh;
  final VoidCallback onDemoMode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
            alignment: Alignment.center,
            child: const Icon(Icons.check, color: Colors.white, size: 32),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text("You're all set", textAlign: TextAlign.center, style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Start with your own data, or explore with sample data first.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onStartFresh, child: const Text('Start Fresh')),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onDemoMode, child: const Text('Explore with Demo Mode')),
          ),
        ],
      ),
    );
  }
}
