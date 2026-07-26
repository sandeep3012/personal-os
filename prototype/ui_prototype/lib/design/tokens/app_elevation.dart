/// Elevation tokens (DOC-033 §6). Flat/tonal by default; elevated only for
/// transient/overlay surfaces.
abstract final class AppElevation {
  static const double card = 0;
  static const double bottomSheet = 1;
  static const double dialog = 3;
  static const double fab = 3;
  static const double appBar = 0;
  static const double appBarScrolled = 2;
  static const double snackBar = 3;
  static const double navigationBar = 2;
}
