import 'package:flutter/material.dart';

/// Provides the Material 3 light and dark themes for Personal OS.
///
/// Usage:
/// ```dart
/// MaterialApp.router(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: ThemeMode.system,
/// );
/// ```
abstract final class AppTheme {
  // Neutral deep-blue seed — calm, professional, readable in both modes.
  static const Color _seedColor = Color(0xFF1565C0);

  /// Light theme.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  /// Dark theme.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
