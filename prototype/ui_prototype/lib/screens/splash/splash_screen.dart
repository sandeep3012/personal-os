import 'package:flutter/material.dart';

import '../../design/tokens/app_spacing.dart';
import '../onboarding/onboarding_screen.dart';

/// DOC-034 Part A §1 — brand moment only, no spinner (sub-second screen).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: const Text('⌂', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Personal OS', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
