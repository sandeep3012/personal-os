import 'package:application/application.dart';
import 'package:feature_sample/src/application/sample_service.dart';

/// Marks the [SampleService] as loaded during the Application Startup Pipeline.
///
/// This step runs after [RuntimeBootstrap] boot completes, inside the
/// [StartupPipeline] orchestrated by [ApplicationModule].
final class SampleStartupStep implements StartupStep {
  @override
  String get name => 'sample-init';

  @override
  Future<void> execute(StartupContext context) async {
    context.locator.get<SampleService>().markLoaded();
  }
}
