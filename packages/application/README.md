# application

Personal OS Application Layer Foundation — v0.7.0

Pure Dart package. No Flutter dependency.

## Dependency position

```
apps/* → features/* → application → platform_runtime → platform_core
```

## What this package provides

| Subsystem | Key types | Status |
|---|---|---|
| **Feature Framework** | `FeatureModule`, `FeatureMetadata`, `FeatureRegistry`, `FeatureException` | ✅ Stable |
| Startup pipeline | `StartupPipeline`, `StartupStep`, `StartupContext` | ✅ Stable |
| Routing | `RouteDefinition`, `RouteRegistry` | ✅ Stable |
| Navigation | `ApplicationRouter`, `NavigationService` | ✅ Stable |
| State | `AsyncState<T>` (domain type — UI binding deferred to ADR-004), `AppState` | ✅ Domain; UI TBD |
| Use cases | `UseCase<I,O>`, `AsyncUseCase<I,O>`, `NoParamsUseCase<O>` | ✅ Stable |
| Validation | `Validator<T>`, `ValidationResult`, `CompositeValidator<T>` | ✅ Stable |
| Messaging | `AppEvent`, `DomainEvent` | ✅ Stable |
| Feature flags | `FeatureFlag`, `FeatureFlagService` | ✅ Interface-only |
| Permissions | `PermissionService`, `PermissionType`, `PermissionStatus` | ⚠️ Provisional |
| Lifecycle | `AppLifecycleService` | ⚠️ Provisional |
| Errors | `NavigationException`, `UseCaseException`, `PermissionException`, `FeatureException` | ✅ Stable |
| DI | `ApplicationModule` | ✅ Stable |

## Feature Framework

Every feature package extends `FeatureModule` to participate in the runtime.

```dart
final class FinanceModule extends FeatureModule {
  const FinanceModule();

  @override
  FeatureMetadata get metadata => const FeatureMetadata(
    id: 'finance',
    name: 'Finance',
    version: '1.0.0',
    description: 'Expense tracking, accounts, and income management.',
  );

  @override
  void registerRoutes(RouteRegistry registry) {
    registry.register(FinanceRoutes.root);
    registry.register(FinanceRoutes.accounts);
    registry.register(FinanceRoutes.expenses);
  }

  @override
  List<StartupStep> get startupSteps => [
    FinanceStorageInitStep(),
  ];

  @override
  void registerServices(IDependencyRegistrar registrar) {
    registrar.registerLazySingleton<IAccountRepository>(
      AccountRepository.new,
    );
  }
}
```

Register feature modules **after** `ApplicationModule`:

```dart
final bootstrap = RuntimeBootstrap()
  ..addModule(AppModule())
  ..addModule(ApplicationModule())   // must come first
  ..addModule(FinanceModule())
  ..addModule(TasksModule());

await bootstrap.boot();
```

## Startup hierarchy

```
RuntimeBootstrap          (platform_runtime — infrastructure)
 ↓
StartupPipeline           (application — orchestration)
 ↓
StartupStep impls         (features — business startup tasks)
```

## Use-case pattern

```dart
final class GetAccountsUseCase
    implements AsyncUseCase<String, List<Account>> {
  const GetAccountsUseCase(this._repo);
  final IAccountRepository _repo;

  @override
  Future<Result<List<Account>>> execute(String userId) =>
      _repo.getByUser(userId);
}
```

## Architecture constraints

- Do NOT import Flutter packages here.
- Feature packages depend on this package; this package does NOT depend on features.
- Concrete implementations of abstract interfaces (`NavigationService`,
  `PermissionService`, `AppLifecycleService`, `FeatureFlagService`) are
  provided by the app layer or adapter packages.
- `ApplicationModule` must always be added to `RuntimeBootstrap` before any
  `FeatureModule` — feature modules resolve `FeatureRegistry`, `RouteRegistry`,
  and `StartupPipeline` from the DI container during their `register()` phase.

## See also

- ADR-001 — Application Layer boundaries
- ADR-002 — AsyncState\<T\> approved as domain type; UI framework deferred
- ADR-003 — Navigation architecture; synchronous route registration
- `docs/architecture/Feature_Template.md` — standard feature package structure
