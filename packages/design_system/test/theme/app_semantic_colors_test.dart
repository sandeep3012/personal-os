import 'dart:math' as math;

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _linearize(double channel) =>
    channel <= 0.03928 ? channel / 12.92 : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

/// WCAG relative luminance of [color].
double _relativeLuminance(Color color) {
  final r = _linearize(color.r);
  final g = _linearize(color.g);
  final b = _linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG contrast ratio between [a] and [b] (always ≥ 1.0).
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  group('AppSemanticColors', () {
    const colors = AppSemanticColors(
      positive: Color(0xFF1E8E3E),
      negative: Color(0xFFC5221F),
      warning: Color(0xFF9A6800),
      neutral: Color(0xFF1A73E8),
      success: Color(0xFF1E8E3E),
      moduleAccents: {'finance': Color(0xFF1565C0)},
    );

    test('moduleAccent returns the registered color for a known module', () {
      expect(colors.moduleAccent('finance'), const Color(0xFF1565C0));
    });

    test('moduleAccent falls back to neutral for an unknown module', () {
      expect(colors.moduleAccent('unknown-module'), colors.neutral);
    });

    test('moduleAccent honors an explicit fallback override', () {
      expect(
        colors.moduleAccent('unknown-module', fallback: Colors.pink),
        Colors.pink,
      );
    });

    test('copyWith overrides only the specified fields', () {
      final copy = colors.copyWith(positive: Colors.black);
      expect(copy.positive, Colors.black);
      expect(copy.negative, colors.negative);
      expect(copy.moduleAccents, colors.moduleAccents);
    });

    test('lerp at t=0 and t=1 returns the expected endpoints', () {
      const other = AppSemanticColors(
        positive: Colors.white,
        negative: Colors.white,
        warning: Colors.white,
        neutral: Colors.white,
        success: Colors.white,
        moduleAccents: {'finance': Colors.white},
      );
      expect(colors.lerp(other, 0).positive, colors.positive);
      expect(colors.lerp(other, 1).positive, other.positive);
    });

    test('lerp against a non-AppSemanticColors extension returns unchanged',
        () {
      expect(colors.lerp(null, 0.5), same(colors));
    });
  });

  group('AppThemeBuilder semantic colors — contrast', () {
    for (final brightness in Brightness.values) {
      test(
          'positive/negative/warning/neutral/success meet a 3:1 contrast '
          'minimum against ${brightness.name} surface', () {
        final theme = AppThemeBuilder.build(
          seedColor: const Color(0xFF1565C0),
          brightness: brightness,
        );
        final colors = theme.extension<AppSemanticColors>()!;
        final surface = theme.colorScheme.surface;

        for (final entry in {
          'positive': colors.positive,
          'negative': colors.negative,
          'warning': colors.warning,
          'neutral': colors.neutral,
          'success': colors.success,
        }.entries) {
          final ratio = _contrastRatio(entry.value, surface);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                '${entry.key} contrast against ${brightness.name} surface was '
                '${ratio.toStringAsFixed(2)}:1, below the 3:1 minimum '
                '(VPS §1.8) for icon/large-text usage',
          );
        }
      });
    }
  });
}
