/// Elevation tokens (VPS §1.4).
///
/// Material 3 favors tonal elevation (surface color shift) over drop
/// shadows for resting content — these values are deliberately low/zero for
/// resting surfaces and reserved for transient/overlay surfaces.
abstract final class AppElevation {
  /// Resting cards — tonal surface only, no shadow.
  static const double card = 0;

  /// Bottom sheets.
  static const double bottomSheet = 1;

  /// Dialogs.
  static const double dialog = 3;

  /// Floating action buttons.
  static const double fab = 3;

  /// AppBar at rest (flat).
  static const double appBar = 0;

  /// AppBar once content has scrolled beneath it.
  static const double appBarScrolled = 2;

  /// Snackbars.
  static const double snackBar = 3;

  /// Bottom navigation bar.
  static const double navigationBar = 2;
}
