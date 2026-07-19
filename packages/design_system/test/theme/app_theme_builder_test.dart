import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _seed = Color(0xFF1565C0);

void main() {
  group('AppThemeBuilder.build', () {
    test('builds a Material 3 ThemeData for each brightness', () {
      for (final brightness in Brightness.values) {
        final theme = AppThemeBuilder.build(seedColor: _seed, brightness: brightness);
        expect(theme.useMaterial3, isTrue);
        expect(theme.brightness, brightness);
      }
    });

    test('registers the AppSemanticColors extension', () {
      final theme = AppThemeBuilder.build(seedColor: _seed, brightness: Brightness.light);
      expect(theme.extension<AppSemanticColors>(), isNotNull);
    });

    test('high contrast changes the resolved color scheme', () {
      final normal = AppThemeBuilder.build(seedColor: _seed, brightness: Brightness.light);
      final highContrast = AppThemeBuilder.build(
        seedColor: _seed,
        brightness: Brightness.light,
        highContrast: true,
      );
      expect(normal.colorScheme.primary, isNot(highContrast.colorScheme.primary));
    });

    test('every required component theme is populated', () {
      final theme = AppThemeBuilder.build(seedColor: _seed, brightness: Brightness.light);
      expect(theme.cardTheme, isNotNull);
      expect(theme.appBarTheme, isNotNull);
      expect(theme.navigationBarTheme, isNotNull);
      expect(theme.navigationRailTheme, isNotNull);
      expect(theme.chipTheme, isNotNull);
      expect(theme.inputDecorationTheme, isNotNull);
      expect(theme.dialogTheme, isNotNull);
      expect(theme.bottomSheetTheme, isNotNull);
      expect(theme.snackBarTheme, isNotNull);
      expect(theme.listTileTheme, isNotNull);
      expect(theme.filledButtonTheme, isNotNull);
      expect(theme.outlinedButtonTheme, isNotNull);
      expect(theme.textButtonTheme, isNotNull);
    });

    test('filled and outlined buttons meet the 48dp minimum tap target', () {
      final theme = AppThemeBuilder.build(seedColor: _seed, brightness: Brightness.light);
      final filledSize = theme.filledButtonTheme.style?.minimumSize
          ?.resolve({});
      final outlinedSize = theme.outlinedButtonTheme.style?.minimumSize
          ?.resolve({});
      expect(filledSize?.height, greaterThanOrEqualTo(48));
      expect(outlinedSize?.height, greaterThanOrEqualTo(48));
    });

    test('card elevation is flat (tonal, not shadow-based) per VPS §1.4', () {
      final theme = AppThemeBuilder.build(seedColor: _seed, brightness: Brightness.light);
      expect(theme.cardTheme.elevation, AppElevation.card);
    });
  });
}
