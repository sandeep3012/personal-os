import 'package:application/src/configuration/feature_flag.dart';

/// Contract for evaluating feature flags at runtime.
///
/// Concrete implementations read from local preferences, remote config
/// (Firebase Remote Config, LaunchDarkly, etc.), or a combination. Provide
/// implementations via DI so features never hard-code the data source.
///
/// Example:
/// ```dart
/// final flags = locator.get<FeatureFlagService>();
/// if (flags.isEnabled(const DarkModeFlag())) {
///   // show dark mode toggle
/// }
/// ```
abstract interface class FeatureFlagService {
  /// Returns the effective value of [flag].
  ///
  /// Falls back to [FeatureFlag.defaultValue] when no override is configured.
  bool isEnabled(FeatureFlag flag);

  /// Returns the effective value for the flag identified by [key].
  ///
  /// Returns `false` when [key] is unknown.
  bool isEnabledByKey(String key);
}
