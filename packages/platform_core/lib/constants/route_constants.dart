/// Named route path constants for the application navigator.
///
/// Feature packages reference these constants rather than hardcoding path
/// strings, ensuring that a route rename propagates to all call sites.
abstract final class RouteConstants {
  RouteConstants._();

  // ── Root ─────────────────────────────────────────────────────────────────

  static const String root = '/';
  static const String onboarding = '/onboarding';

  // ── Dashboard ─────────────────────────────────────────────────────────────

  static const String dashboard = '/dashboard';

  // ── Settings ─────────────────────────────────────────────────────────────

  static const String settings = '/settings';
  static const String settingsTheme = '/settings/theme';
  static const String settingsLocale = '/settings/locale';
}
