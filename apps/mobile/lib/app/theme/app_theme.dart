import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Provides the Material 3 light and dark themes for Personal OS.
///
/// A thin wrapper around [AppThemeBuilder] (TIS §6 "Theme structure") — this
/// class owns only the app's seed color (product identity); every
/// component theme, semantic color, and typography rule is built by
/// [AppThemeBuilder] in `package:design_system`, shared by every module.
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
  static ThemeData get light => buildLight();

  /// Dark theme.
  static ThemeData get dark => buildDark();

  /// Builds the light theme, optionally in high-contrast mode
  /// (`MediaQuery.highContrastOf(context)` — TIS §6 "High contrast").
  static ThemeData buildLight({bool highContrast = false}) => AppThemeBuilder.build(
        seedColor: _seedColor,
        brightness: Brightness.light,
        highContrast: highContrast,
      );

  /// Builds the dark theme, optionally in high-contrast mode.
  static ThemeData buildDark({bool highContrast = false}) => AppThemeBuilder.build(
        seedColor: _seedColor,
        brightness: Brightness.dark,
        highContrast: highContrast,
      );
}
