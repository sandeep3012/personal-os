import 'package:flutter/material.dart';

/// Product-meaning colors and per-module accents (DOC-033 §2.3–2.4).
///
/// Values copied from the approved DOC-033 table — not imported from
/// `packages/design_system` so the prototype has zero production
/// dependency.
class AppSemanticColors {
  const AppSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.neutral,
    required this.success,
    required this.moduleAccents,
  });

  final Color positive;
  final Color negative;
  final Color warning;
  final Color neutral;
  final Color success;
  final Map<String, Color> moduleAccents;

  Color moduleAccent(String moduleId) => moduleAccents[moduleId] ?? neutral;

  static AppSemanticColors of(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return AppSemanticColors(
      positive: isDark ? const Color(0xFF81C995) : const Color(0xFF1E8E3E),
      negative: isDark ? const Color(0xFFF28B82) : const Color(0xFFC5221F),
      warning: isDark ? const Color(0xFFFDD663) : const Color(0xFF9A6800),
      neutral: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
      success: isDark ? const Color(0xFF81C995) : const Color(0xFF1E8E3E),
      moduleAccents: {
        'finance': isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1565C0),
        'tasks': isDark ? const Color(0xFFD7AEFB) : const Color(0xFF8430CE),
        'habits': isDark ? const Color(0xFFFDBA74) : const Color(0xFFB7590E),
        'goals': isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
        'notes': isDark ? const Color(0xFFFFF59D) : const Color(0xFFF9A825),
        'calendar': isDark ? const Color(0xFFF28B82) : const Color(0xFFC5221F),
        'documents': isDark ? const Color(0xFFBCAAA4) : const Color(0xFF6D4C41),
        'assets': isDark ? const Color(0xFFAEC6FA) : const Color(0xFF3949AB),
      },
    );
  }
}
