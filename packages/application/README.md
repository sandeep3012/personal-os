# application

Personal OS Application Layer Foundation.

Pure Dart package. No Flutter dependency.

## Dependency position

```
apps/* → features/* → application → platform_runtime → platform_core
```

## What this package provides

| Subsystem | Key types |
|---|---|
| Startup pipeline | `StartupPipeline`, `StartupStep`, `StartupContext` |
| Routing | `RouteDefinition`, `RouteRegistry` |
| Navigation | `ApplicationRouter`, `NavigationService`, `DeepLink` |
| State | `AsyncState<T>` (`LoadingState`, `SuccessState`, `ErrorState`), `AppState` |
| Use cases | `UseCase<I,O>`, `AsyncUseCase<I,O>`, `NoParamsUseCase<O>` |
| Validation | `Validator<T>`, `ValidationResult`, `CompositeValidator<T>` |
| Messaging | `AppEvent`, `DomainEvent` (IEventBus/EventBus from platform_runtime) |
| Permissions | `PermissionService`, `PermissionType`, `PermissionStatus` |
| Lifecycle | `AppLifecycleService` |
| Configuration | `BuildFlavor`, `FeatureFlag`, `FeatureFlagService`, `AppConfiguration` |
| Errors | `NavigationException`, `UseCaseException`, `PermissionException` |
| DI | `ApplicationModule` |

## Usage

```dart
import 'package:application/application.dart';
```

Add `ApplicationModule` to the runtime bootstrap:

```dart
final bootstrap = RuntimeBootstrap()
  ..addModule(AppModule())
  ..addModule(ApplicationModule());

await bootstrap.boot();
```

Implement a use case:

```dart
final class LoadDashboardUseCase implements AsyncUseCase<String, Dashboard> {
  const LoadDashboardUseCase(this._repo);
  final DashboardRepository _repo;

  @override
  Future<Result<Dashboard>> execute(String userId) => _repo.findByUser(userId);
}
```

## Architecture constraints

- Do NOT import Flutter packages here.
- Feature packages depend on this package; this package does NOT depend on features.
- Concrete implementations of abstract interfaces (NavigationService,
  PermissionService, AppLifecycleService, FeatureFlagService) are provided by
  the app layer or adapter packages.
