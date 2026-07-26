import 'package:design_system/src/theme/app_semantic_colors.dart';
import 'package:design_system/src/tokens/app_elevation.dart';
import 'package:design_system/src/tokens/app_icon_sizes.dart';
import 'package:design_system/src/tokens/app_radius.dart';
import 'package:design_system/src/tokens/app_spacing.dart';
import 'package:design_system/src/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Builds a complete, consistent [ThemeData] for Personal OS.
///
/// The *app* owns the seed color (product identity); this builder owns how
/// that seed becomes every component theme + [AppSemanticColors] extension
/// — the single place elevation/radius/typography/color rules from VPS §1
/// become enforceable defaults instead of per-widget choices (TIS §6).
///
/// `apps/mobile`'s `AppTheme` is a thin wrapper calling [AppThemeBuilder.build].
abstract final class AppThemeBuilder {
  /// Builds the full [ThemeData] for [brightness] from [seedColor].
  ///
  /// [highContrast] maps to `ColorScheme.fromSeed`'s `contrastLevel` — set
  /// from `MediaQuery.highContrastOf(context)` at the app root (TIS §6
  /// "High contrast").
  static ThemeData build({
    required Color seedColor,
    required Brightness brightness,
    bool highContrast = false,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      contrastLevel: highContrast ? 1.0 : 0.0,
    );
    final textTheme = AppTypography.textTheme(brightness);
    final semanticColors = _semanticColors(brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      extensions: [semanticColors],
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme, textTheme),
      navigationBarTheme: _navigationBarTheme(colorScheme),
      navigationRailTheme: _navigationRailTheme(colorScheme),
      chipTheme: _chipTheme(colorScheme, textTheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      dialogTheme: _dialogTheme(colorScheme),
      bottomSheetTheme: _bottomSheetTheme(colorScheme),
      snackBarTheme: _snackBarTheme(colorScheme, textTheme),
      listTileTheme: _listTileTheme(colorScheme),
      filledButtonTheme: _filledButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      textButtonTheme: _textButtonTheme(colorScheme),
      floatingActionButtonTheme: _floatingActionButtonTheme(colorScheme),
      progressIndicatorTheme: _progressIndicatorTheme(colorScheme),
      segmentedButtonTheme: _segmentedButtonTheme(colorScheme, textTheme),
      dividerTheme: _dividerTheme(colorScheme),
      iconTheme: _iconTheme(colorScheme),
    );
  }

  static CardThemeData _cardTheme(ColorScheme scheme) => CardThemeData(
        elevation: AppElevation.card,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      );

  static AppBarTheme _appBarTheme(ColorScheme scheme, TextTheme textTheme) =>
      AppBarTheme(
        elevation: AppElevation.appBar,
        scrolledUnderElevation: AppElevation.appBarScrolled,
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        foregroundColor: scheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
      );

  static NavigationBarThemeData _navigationBarTheme(ColorScheme scheme) =>
      NavigationBarThemeData(
        elevation: AppElevation.navigationBar,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
      );

  static NavigationRailThemeData _navigationRailTheme(ColorScheme scheme) =>
      NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        useIndicator: true,
      );

  static ChipThemeData _chipTheme(ColorScheme scheme, TextTheme textTheme) =>
      ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
      );

  static InputDecorationTheme _inputDecorationTheme(ColorScheme scheme) =>
      InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          borderSide: BorderSide.none,
        ),
      );

  static DialogThemeData _dialogTheme(ColorScheme scheme) => DialogThemeData(
        elevation: AppElevation.dialog,
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
      );

  static BottomSheetThemeData _bottomSheetTheme(ColorScheme scheme) =>
      BottomSheetThemeData(
        elevation: AppElevation.bottomSheet,
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
      );

  static SnackBarThemeData _snackBarTheme(
    ColorScheme scheme,
    TextTheme textTheme,
  ) =>
      SnackBarThemeData(
        elevation: AppElevation.snackBar,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xs),
        ),
      );

  static ListTileThemeData _listTileTheme(ColorScheme scheme) =>
      ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        minLeadingWidth: AppSpacing.xl,
        iconColor: scheme.onSurfaceVariant,
      );

  static FilledButtonThemeData _filledButtonTheme(ColorScheme scheme) =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme scheme) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.lg),
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme(ColorScheme scheme) =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      );

  /// FAB elevation/color per VPS §1.4 — the most prominent interactive
  /// surface on its screen, same prominence tier as [_dialogTheme].
  static FloatingActionButtonThemeData _floatingActionButtonTheme(ColorScheme scheme) =>
      FloatingActionButtonThemeData(
        elevation: AppElevation.fab,
        focusElevation: AppElevation.fab,
        hoverElevation: AppElevation.fab,
        highlightElevation: AppElevation.fab,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      );

  /// Linear/circular progress indicators (VPS §2 — [ProportionBar]'s and
  /// loading spinners' track) — a visible, consistently-colored track
  /// instead of each call site relying on the platform default.
  static ProgressIndicatorThemeData _progressIndicatorTheme(ColorScheme scheme) =>
      ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      );

  /// Segmented controls (e.g. Expense/Income in a transaction form) —
  /// selected segment matches [_chipTheme]'s selected color so both
  /// "choose one" affordances read as the same interaction family.
  static SegmentedButtonThemeData _segmentedButtonTheme(
    ColorScheme scheme,
    TextTheme textTheme,
  ) =>
      SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.secondaryContainer
                : scheme.surface,
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.lg)),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
        ),
      );

  /// Dividers/list separators (VPS §2.2 "Divider") — always [outlineVariant],
  /// never a raw grey literal.
  static DividerThemeData _dividerTheme(ColorScheme scheme) => DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.md,
      );

  /// Default icon size/color for bare `Icon` widgets outside AppBar/ListTile
  /// (which set their own via [_appBarTheme]/[_listTileTheme]) — the
  /// [AppIconSizes.standard] token, never a per-screen literal.
  static IconThemeData _iconTheme(ColorScheme scheme) => IconThemeData(
        size: AppIconSizes.standard,
        color: scheme.onSurfaceVariant,
      );

  /// The [AppSemanticColors] extension for [brightness].
  ///
  /// Values are chosen to meet WCAG contrast minimums (VPS §1.8) against
  /// both light and dark `ColorScheme.surface` — verified by
  /// `app_semantic_colors_test.dart`'s contrast-ratio assertions, not by
  /// manual review alone.
  static AppSemanticColors _semanticColors(Brightness brightness) {
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
        'ai': isDark ? const Color(0xFF80CBC4) : const Color(0xFF00695C),
      },
    );
  }
}
