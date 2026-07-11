/// A named boolean feature toggle.
///
/// Implement [FeatureFlag] once per flag and pass instances to
/// [FeatureFlagService.isEnabled]. The [defaultValue] is used when no remote
/// or local override is available.
///
/// Example:
/// ```dart
/// final class DarkModeFlag implements FeatureFlag {
///   const DarkModeFlag();
///
///   @override
///   String get key => 'dark_mode';
///
///   @override
///   bool get defaultValue => true;
/// }
/// ```
abstract interface class FeatureFlag {
  /// The stable string key used to look up the flag's value from any source.
  String get key;

  /// The value used when no override is present.
  bool get defaultValue;
}
