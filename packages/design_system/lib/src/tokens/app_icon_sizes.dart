/// Icon size tokens (VPS §1.5).
///
/// One icon size per context, reused everywhere — no screen picks its own
/// icon size literal.
abstract final class AppIconSizes {
  /// Inline, inside text rows (e.g. a delta arrow next to a stat value).
  static const double inline = 20;

  /// Default — list leading icons, AppBar actions.
  static const double standard = 24;

  /// Module/avatar icons (e.g. a `ModuleCard`'s leading icon).
  static const double avatar = 32;

  /// Empty-state and large illustrative icons.
  static const double empty = 48;
}
