/// Keys used for local persistent storage.
///
/// Centralised here to prevent key collisions between features. Keys are
/// namespaced by feature prefix (e.g. `'auth.'`, `'finance.'`).
///
/// StorageException and actual storage calls live in the `storage` package —
/// these are the raw string constants only.
abstract final class StorageKeys {
  StorageKeys._();

  // ── App ──────────────────────────────────────────────────────────────────

  /// Whether the user has completed the onboarding flow.
  static const String onboardingComplete = 'app.onboarding_complete';

  /// ISO 8601 date-time of the last successful sync.
  static const String lastSyncTime = 'app.last_sync_time';

  // ── Theme ─────────────────────────────────────────────────────────────────

  /// User's preferred theme mode (`'light'`, `'dark'`, `'system'`).
  static const String themeMode = 'app.theme_mode';

  // ── Locale ───────────────────────────────────────────────────────────────

  /// User's preferred locale (BCP 47 language tag).
  static const String preferredLocale = 'app.preferred_locale';
}
