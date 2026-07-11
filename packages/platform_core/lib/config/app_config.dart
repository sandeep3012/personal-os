import 'package:platform_core/environment/build_environment.dart';

/// Immutable application configuration passed through the dependency graph.
///
/// [AppConfig] is constructed once at startup (in `main.dart`) and injected
/// wherever configuration is needed. No singleton, no global access.
///
/// Example:
/// ```dart
/// const config = AppConfig(
///   appName: 'Personal OS',
///   environment: BuildEnvironment.development,
///   version: '1.0.0',
/// );
/// ```
final class AppConfig {
  const AppConfig({
    required this.appName,
    required this.environment,
    this.version = '0.0.0',
    this.buildNumber = '0',
  });

  /// Human-readable application name.
  final String appName;

  /// The deployment environment this build targets.
  final BuildEnvironment environment;

  /// Semantic version string (e.g. `'1.2.3'`).
  final String version;

  /// Platform-specific build number.
  final String buildNumber;

  // ── Convenience ───────────────────────────────────────────────────────────

  bool get isDevelopment => environment.isDevelopment;
  bool get isStaging => environment.isStaging;
  bool get isProduction => environment.isProduction;

  // ── Value semantics ───────────────────────────────────────────────────────

  AppConfig copyWith({
    String? appName,
    BuildEnvironment? environment,
    String? version,
    String? buildNumber,
  }) =>
      AppConfig(
        appName: appName ?? this.appName,
        environment: environment ?? this.environment,
        version: version ?? this.version,
        buildNumber: buildNumber ?? this.buildNumber,
      );

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      appName == other.appName &&
      environment == other.environment &&
      version == other.version &&
      buildNumber == other.buildNumber;

  @override
  int get hashCode =>
      Object.hash(appName, environment, version, buildNumber);

  @override
  String toString() =>
      'AppConfig(appName: $appName, environment: $environment, '
      'version: $version, buildNumber: $buildNumber)';
}
