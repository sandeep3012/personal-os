import 'package:flutter/widgets.dart';

/// Material 3 window-size classes (VPS §1.7 / TIS §4).
///
/// Drives the [AppShell]'s Bottom-Nav-vs-Rail decision and any other
/// screen's responsive layout branching. A single source of truth so no
/// two screens disagree on where "Compact" ends and "Medium" begins.
enum AppWindowSizeClass {
  /// <600dp — phones in portrait.
  compact,

  /// 600–839dp — phones in landscape, small tablets, foldables.
  medium,

  /// ≥840dp — tablets, desktop.
  expanded,
}

/// Simple, reusable responsive-breakpoint API.
///
/// Usage: `AppBreakpoints.of(context)` or `AppBreakpoints.fromWidth(width)`.
abstract final class AppBreakpoints {
  static const double mediumMinWidth = 600;
  static const double expandedMinWidth = 840;

  /// The [AppWindowSizeClass] for the current [BuildContext]'s width.
  static AppWindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// The [AppWindowSizeClass] for an explicit [width] — useful where a
  /// `BuildContext` isn't available yet (e.g. deciding layout before the
  /// first frame) or in unit tests.
  static AppWindowSizeClass fromWidth(double width) {
    if (width >= expandedMinWidth) return AppWindowSizeClass.expanded;
    if (width >= mediumMinWidth) return AppWindowSizeClass.medium;
    return AppWindowSizeClass.compact;
  }

  /// Convenience: true at Medium or Expanded width (i.e. "wide enough for a
  /// rail instead of a bottom bar").
  static bool isAtLeastMedium(BuildContext context) =>
      of(context) != AppWindowSizeClass.compact;

  /// Convenience: true only at Expanded width.
  static bool isExpanded(BuildContext context) =>
      of(context) == AppWindowSizeClass.expanded;
}
