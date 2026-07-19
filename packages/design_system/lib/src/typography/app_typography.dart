import 'package:flutter/material.dart';

/// The Personal OS type scale (VPS §1.2).
///
/// Builds on Material 3's `Typography.material2021` base and tunes the
/// specific weights this product's role table calls for. [AppThemeBuilder]
/// applies this once per brightness; no screen defines its own inline
/// `TextStyle` for a role already covered here.
abstract final class AppTypography {
  /// Returns the full [TextTheme] for [brightness], seeded from Material's
  /// 2021 type scale and tuned per VPS §1.2's role table.
  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return base.copyWith(
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
