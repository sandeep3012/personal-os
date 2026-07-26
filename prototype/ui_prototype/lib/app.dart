import 'package:flutter/material.dart';

import 'design/theme/app_theme.dart';
import 'screens/splash/splash_screen.dart';

/// Root widget of the UI prototype — a clickable design review build.
/// No DI, no ViewModels, no repositories: `MaterialApp` → `SplashScreen`.
class PrototypeApp extends StatelessWidget {
  const PrototypeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal OS — UI Prototype',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
