import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTypography.textTheme', () {
    test('tuned roles use w600 weight per VPS §1.2', () {
      for (final brightness in Brightness.values) {
        final textTheme = AppTypography.textTheme(brightness);
        expect(textTheme.headlineSmall?.fontWeight, FontWeight.w600);
        expect(textTheme.titleLarge?.fontWeight, FontWeight.w600);
        expect(textTheme.titleMedium?.fontWeight, FontWeight.w600);
        expect(textTheme.titleSmall?.fontWeight, FontWeight.w600);
        expect(textTheme.labelLarge?.fontWeight, FontWeight.w600);
      }
    });

    test('every text role is non-null', () {
      final textTheme = AppTypography.textTheme(Brightness.light);
      expect(textTheme.bodyLarge, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.bodySmall, isNotNull);
      expect(textTheme.labelMedium, isNotNull);
      expect(textTheme.labelSmall, isNotNull);
    });
  });
}
