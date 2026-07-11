import 'package:application/src/startup/startup_context.dart';
import 'package:application/src/startup/startup_step.dart';

/// The Application Startup Pipeline — middle tier of the three-level startup hierarchy.
///
/// ## Startup hierarchy (approved in ADR-001 / ADR-003)
///
/// ```
/// RuntimeBootstrap          (platform_runtime)
///   Owns: infrastructure setup, ServiceRegistry, EventBus, module lifecycle
///    ↓
/// StartupPipeline           (application — this class)
///   Owns: application-level orchestration of feature startup tasks
///    ↓
/// StartupStep impls         (feature packages)
///   Own: per-feature initialisation (storage, analytics, config, etc.)
/// ```
///
/// `RuntimeBootstrap` calls [execute] once from within its `onStart` phase
/// (via [ApplicationModule]). Steps run sequentially in registration order;
/// each step receives the same [StartupContext] so later steps can consume
/// services registered by earlier ones.
///
/// ## Example
///
/// ```dart
/// final pipeline = StartupPipeline()
///   ..addStep(StorageInitStep())
///   ..addStep(ConfigurationLoadStep())
///   ..addStep(AnalyticsInitStep());
///
/// await pipeline.execute(StartupContext(locator: registry, config: config));
/// ```
final class StartupPipeline {
  final _steps = <StartupStep>[];

  /// Returns an unmodifiable view of all registered steps, in registration order.
  List<StartupStep> get steps => List.unmodifiable(_steps);

  /// Appends [step] to the end of the pipeline.
  ///
  /// Must be called before [execute]; adding steps after execution has started
  /// is not prevented but the step will not run in the current execution.
  void addStep(StartupStep step) {
    _steps.add(step);
  }

  /// Appends every step in [steps] to the pipeline in list order.
  void addSteps(List<StartupStep> steps) {
    _steps.addAll(steps);
  }

  /// Executes every registered step sequentially, passing [context] to each.
  ///
  /// Throws if any step throws; subsequent steps are not executed.
  Future<void> execute(StartupContext context) async {
    for (final step in _steps) {
      await step.execute(context);
    }
  }
}
