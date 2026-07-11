/// The deployment environment the application is running in.
enum BuildEnvironment {
  /// Local development — verbose logging enabled, debug features visible.
  development,

  /// Pre-production validation — mirrors production config with test data.
  staging,

  /// Live user-facing release — minimal logging, all debug features hidden.
  production,
}

/// Convenience extensions on [BuildEnvironment].
extension BuildEnvironmentX on BuildEnvironment {
  bool get isDevelopment => this == BuildEnvironment.development;
  bool get isStaging => this == BuildEnvironment.staging;
  bool get isProduction => this == BuildEnvironment.production;

  /// `true` for any non-production environment.
  bool get isDebugLike =>
      this == BuildEnvironment.development || this == BuildEnvironment.staging;
}
