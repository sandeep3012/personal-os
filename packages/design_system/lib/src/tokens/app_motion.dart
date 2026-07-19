import 'package:flutter/widgets.dart';

/// Motion tokens (VPS §1.6).
///
/// No widget owns its own animation duration or curve — every animation in
/// the app is built from these constants, and every duration is routed
/// through [durationOrZero] so reduced-motion accessibility settings are
/// respected in exactly one place (TIS §11).
abstract final class AppMotion {
  /// Micro-interactions: chip select, checkbox toggle.
  static const Duration fast = Duration(milliseconds: 200);

  /// State transitions: Loading ⇄ Content ⇄ Empty ⇄ Error.
  static const Duration standard = Duration(milliseconds: 250);

  /// Page/shared-axis transitions.
  static const Duration page = Duration(milliseconds: 300);

  /// Explicitly-justified celebration moments only (goal completion, streak
  /// milestone) — never used for routine UI feedback.
  static const Duration celebration = Duration(milliseconds: 600);

  /// The default entry curve (M3 emphasized-standard equivalent).
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// The default exit curve.
  static const Curve decelerateCurve = Curves.decelerate;

  /// Returns [duration] unless the platform's reduced-motion accessibility
  /// setting is enabled (`MediaQuery.disableAnimations`), in which case
  /// returns [Duration.zero] — the single foundation point every animated
  /// widget should call through, rather than each widget checking
  /// `MediaQuery` itself (VPS §1.6 / TIS §11 "Reduced motion").
  static Duration durationOrZero(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
