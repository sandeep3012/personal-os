# feature_sample

**Purpose:** Feature Framework validation reference implementation.

This is NOT a business feature. It exists only to validate that the Personal OS
Feature Framework (Sprint 7) works end-to-end before the first real feature
(Finance) is implemented in Sprint 8.

## What this package exercises

| Framework area | Component used |
|---|---|
| Feature registration | `FeatureModule.metadata` → `FeatureRegistry` |
| Route registration | `SampleRoutes.root` → `RouteRegistry` |
| Startup pipeline | `SampleStartupStep` → `StartupPipeline` |
| DI registration | `SampleService` (singleton), `GetSampleStatusUseCase` (factory) |
| Use case contract | `GetSampleStatusUseCase implements NoParamsUseCase<String>` |
| Application service | `SampleService` (tracks load state) |
| Flutter screen | `SamplePage` (displays status from `SampleService`) |
| Lifecycle hooks | `onInit`, `onStart`, `onStop`, `onDispose` (all no-ops — validated as completes) |

## Dependency structure

```
feature_sample
  ↓
application     (FeatureModule, UseCase, RouteDefinition, StartupStep, …)
  ↓
platform_runtime
  ↓
platform_core
```

`feature_sample` does **not** import `platform_runtime` or `platform_core` directly.

## Registration in apps/mobile

```dart
final bootstrap = RuntimeBootstrap()
  ..addModule(AppModule())
  ..addModule(ApplicationModule())   // must be first
  ..addModule(const SampleModule());

await bootstrap.boot();
```

## Screen navigation

The sample screen is reachable at `/sample`. From the Home screen, tap
**"Open Sample Feature"** to navigate there via go_router.

## Tests

```bash
# From repo root
flutter test features/sample
```

- `test/di/sample_module_test.dart` — 17 tests covering all framework integration points
- `test/application/sample_service_test.dart` — 5 tests
- `test/domain/get_sample_status_use_case_test.dart` — 3 tests

## Validation status

| Check | Result |
|---|---|
| Feature registration | ✅ |
| Route registration | ✅ |
| Startup pipeline | ✅ |
| DI registration | ✅ |
| Use case end-to-end | ✅ |
| Flutter screen | ✅ (manual) |
| Navigation | ✅ (go_router) |
| Lifecycle hooks | ✅ |

## Removal

This package should be removed or replaced with a `testing_support` package
once Sprint 8 (Finance MVP) is underway. It must not appear in production
builds unless explicitly gated.
