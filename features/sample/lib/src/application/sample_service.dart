/// Application service for the Sample feature.
///
/// Tracks whether [SampleStartupStep] has executed and exposes a human-readable
/// status string for display in [SamplePage].
///
/// Registered as a singleton by [SampleModule].
final class SampleService {
  bool _loaded = false;

  /// Whether the Sample feature's startup step has completed.
  bool get isLoaded => _loaded;

  /// Marks the feature as successfully loaded.
  ///
  /// Called by [SampleStartupStep] during the Application Startup Pipeline.
  void markLoaded() => _loaded = true;

  /// A human-readable status string reflecting [isLoaded].
  String get status =>
      _loaded ? 'Sample Feature Loaded Successfully' : 'Initializing…';
}
