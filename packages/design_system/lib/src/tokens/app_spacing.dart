/// The Personal OS 4pt spacing scale (VPS §1.1).
///
/// Every `Padding`/`SizedBox`/`EdgeInsets` value anywhere in the app should
/// reference one of these constants rather than a raw numeric literal — this
/// is what keeps rhythm consistent across every module (TIS §13 rule #4).
abstract final class AppSpacing {
  /// 4dp — icon-to-label gaps, chip internal padding.
  static const double xs = 4;

  /// 8dp — between related inline elements.
  static const double sm = 8;

  /// 16dp — default screen margin, card internal padding, list-item
  /// vertical rhythm.
  static const double md = 16;

  /// 24dp — between distinct sections on a screen.
  static const double lg = 24;

  /// 32dp — above/below the first section on a screen, empty-state
  /// vertical centering.
  static const double xl = 32;

  /// 48dp — major screen-to-screen breathing room on tablet/desktop.
  static const double xxl = 48;
}
