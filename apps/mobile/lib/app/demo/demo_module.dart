import 'package:personal_os/app/demo/demo_mode_controller.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Registers the pre-built [DemoModeController] (constructed in
/// [AppBootstrap.boot], where the switchable executor/runner and the real
/// file-backed pair are assembled) so Settings/Onboarding can resolve it via
/// DI exactly like any other app-layer service.
final class DemoModule extends RuntimeModule {
  const DemoModule({required this.controller});

  final DemoModeController controller;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerSingleton<DemoModeController>(controller);
  }
}
