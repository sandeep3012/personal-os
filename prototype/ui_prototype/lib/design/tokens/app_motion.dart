import 'package:flutter/widgets.dart';

/// Motion tokens (DOC-033 §15). `celebration` is reserved for Goals/Habits
/// milestone moments only — never routine UI feedback.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration page = Duration(milliseconds: 300);
  static const Duration celebration = Duration(milliseconds: 600);

  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve decelerateCurve = Curves.decelerate;
}
