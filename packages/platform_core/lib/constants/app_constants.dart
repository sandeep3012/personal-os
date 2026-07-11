/// Top-level application constants.
///
/// All values are `static const` and must be purely informational — no
/// business logic, no platform detection, no mutable state.
abstract final class AppConstants {
  AppConstants._();

  /// Official application display name.
  static const String appName = 'Personal OS';

  /// Minimum supported Android API level.
  static const int minAndroidSdk = 21;

  /// Minimum supported iOS version.
  static const String minIosVersion = '14.0';

  /// ISO 639-1 code for the default locale.
  static const String defaultLocale = 'en';

  /// Default request/operation timeout duration in seconds.
  static const int defaultTimeoutSeconds = 30;

  /// Maximum number of retry attempts for transient failures.
  static const int maxRetryAttempts = 3;
}
