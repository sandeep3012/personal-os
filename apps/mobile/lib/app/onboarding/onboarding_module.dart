import 'package:personal_os/app/onboarding/onboarding_status_store.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/modules/runtime_module.dart';

/// Registers the pre-built [OnboardingStatusStore] (constructed in
/// [AppBootstrap.boot], which also resolves the store's file path — async,
/// via `path_provider` in production) so the app layer can mark onboarding
/// completed from any exit path (Skip/Start Fresh/Demo Mode).
final class OnboardingModule extends RuntimeModule {
  const OnboardingModule({required this.store});

  final OnboardingStatusStore store;

  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerSingleton<OnboardingStatusStore>(store);
  }
}
