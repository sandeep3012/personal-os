/// Corner-radius tokens (VPS §1.4).
///
/// Referenced by [AppThemeBuilder]'s component themes — no screen or
/// component should set its own `BorderRadius` literal.
abstract final class AppRadius {
  /// Resting cards, `StatCard`/tile-family components.
  static const double card = 16;

  /// Dialogs and bottom sheets (top corners).
  static const double large = 28;

  /// Chips (stadium/full radius) — computed by the consumer as
  /// `BorderRadius.circular(9999)` or via `StadiumBorder`, this constant
  /// documents the intent rather than a literal value.
  static const double chipStadium = 9999;
}
