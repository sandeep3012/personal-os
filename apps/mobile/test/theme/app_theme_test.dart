import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_os/app/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    group('light', () {
      test('uses Material 3', () {
        expect(AppTheme.light.useMaterial3, isTrue);
      });

      test('has light brightness', () {
        expect(
          AppTheme.light.colorScheme.brightness,
          Brightness.light,
        );
      });

      test('is not null', () {
        expect(AppTheme.light, isNotNull);
      });
    });

    group('dark', () {
      test('uses Material 3', () {
        expect(AppTheme.dark.useMaterial3, isTrue);
      });

      test('has dark brightness', () {
        expect(
          AppTheme.dark.colorScheme.brightness,
          Brightness.dark,
        );
      });

      test('is not null', () {
        expect(AppTheme.dark, isNotNull);
      });
    });

    test('light and dark themes have different color schemes', () {
      expect(
        AppTheme.light.colorScheme.surface,
        isNot(equals(AppTheme.dark.colorScheme.surface)),
      );
    });
  });
}
