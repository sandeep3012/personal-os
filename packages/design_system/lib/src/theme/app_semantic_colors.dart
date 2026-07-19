import 'package:flutter/material.dart';

/// Product-meaning colors that aren't part of Material's `ColorScheme`
/// (VPS §1.3): positive/negative/warning/neutral/success states, plus a
/// per-module accent color used to visually identify "which module am I
/// in" on Home and section headers.
///
/// Registered on [ThemeData.extensions] by [AppThemeBuilder] — read via
/// `Theme.of(context).extension<AppSemanticColors>()!`. Color is never the
/// only signal of meaning anywhere in the app (VPS §1.8) — these tokens
/// pair with text/icons, never used alone.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.neutral,
    required this.success,
    required this.moduleAccents,
  });

  /// Income, gains, on-track figures.
  final Color positive;

  /// Expenses, overdue items, off-track figures.
  final Color negative;

  /// Upcoming bills, low-balance cautions.
  final Color warning;

  /// Transfers, pending states — neither positive nor negative.
  final Color neutral;

  /// Completed tasks/habits, goals reached.
  final Color success;

  /// Per-module accent colors, keyed by module id (`'finance'`, `'tasks'`,
  /// `'habits'`, `'goals'`, `'calendar'`, `'documents'`, `'assets'`, `'ai'`).
  final Map<String, Color> moduleAccents;

  /// The accent color for [moduleId], or [fallback] (defaulting to
  /// [neutral]) if that module has no registered accent.
  Color moduleAccent(String moduleId, {Color? fallback}) =>
      moduleAccents[moduleId] ?? fallback ?? neutral;

  @override
  AppSemanticColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? neutral,
    Color? success,
    Map<String, Color>? moduleAccents,
  }) {
    return AppSemanticColors(
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      neutral: neutral ?? this.neutral,
      success: success ?? this.success,
      moduleAccents: moduleAccents ?? this.moduleAccents,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      success: Color.lerp(success, other.success, t)!,
      moduleAccents: t < 0.5 ? moduleAccents : other.moduleAccents,
    );
  }
}
