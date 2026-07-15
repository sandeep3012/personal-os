# Feature Template

**Version:** 1.0
**Status:** Accepted
**Applies from:** v0.7.0 (Feature Framework)
**Related documents:** ADR-001, ADR-003, DOC-023, DOC-018
**Package:** `packages/application` — `FeatureModule`, `FeatureMetadata`, `FeatureRegistry`

---

## Purpose

Defines the canonical structure every Personal OS feature package must follow.

Every feature (Finance, Notes, Tasks, Calendar, Knowledge, Habits …) is an
isolated Dart package under `features/`. Each package follows this template.
Consistency enables tooling, testing, and onboarding at scale.

---

## Dependency Rule

```
apps/*
  ↓
features/*         ← feature packages live here
  ↓
application        ← FeatureModule, UseCase, NavigationService, Validation, …
  ↓
platform_runtime
  ↓
platform_core
```

A feature package imports **only** `application` (and `shared` if needed).
It **never** imports another feature package.
It **never** imports `platform_runtime` or `platform_core` directly.

---

## Folder Structure

```
features/
  [feature_name]/                        e.g. features/finance/
    lib/
      src/
        domain/
          entities/                      # Core business objects — plain Dart
          repositories/                  # Abstract interfaces (implemented in data/)
          use_cases/                     # Domain business rules (implement UseCase)
        data/
          repositories/                  # Concrete implementations of domain repos
          datasources/                   # Local (platform_storage) or remote sources
          models/                        # Persistence/DTO models
        presentation/                    # Flutter UI — deferred until ADR-004
          pages/
          widgets/
        di/
          [feature_name]_module.dart     # extends FeatureModule
        routes/
          [feature_name]_routes.dart     # RouteDefinition constants
      [feature_name].dart                # Public barrel — export only public API
    test/
      domain/
        use_cases/
        entities/
      data/
        repositories/
      di/
        [feature_name]_module_test.dart
    pubspec.yaml
    README.md
```

---

## pubspec.yaml

```yaml
name: feature_[name]
description: Personal OS — [Name] Feature
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ">=3.11.0 <4.0.0"

dependencies:
  application: any          # ← only required project dependency
  # shared: any             # add only if shared UI components are needed

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.0
```

Add `features/feature_[name]` to the workspace `pubspec.yaml` at the
repository root.

---

## FeatureModule implementation

```dart
// features/finance/lib/src/di/finance_module.dart
import 'package:application/application.dart';

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
    registrar.registerLazySingleton<IExpenseRepository>(
      ExpenseRepository.new,
    );
  }
}
```

---

## Route constants

```dart
// features/finance/lib/src/routes/finance_routes.dart
import 'package:application/application.dart';

abstract final class FinanceRoutes {
  static const root = RouteDefinition(
    path: '/finance',
    name: 'finance',
  );
  static const accounts = RouteDefinition(
    path: '/finance/accounts',
    name: 'financeAccounts',
  );
  static const expenses = RouteDefinition(
    path: '/finance/expenses',
    name: 'financeExpenses',
  );
}
```

---

## Domain layer — entities and repositories

```dart
// features/finance/lib/src/domain/entities/account.dart
final class Account {
  const Account({required this.id, required this.name, required this.balance});
  final String id;
  final String name;
  final double balance;
}

// features/finance/lib/src/domain/repositories/i_account_repository.dart
import 'package:platform_core/result/result.dart';
import '../entities/account.dart';

abstract interface class IAccountRepository {
  Future<Result<List<Account>>> getAll();
  Future<Result<Account>> getById(String id);
  Future<Result<void>> save(Account account);
}
```

---

## Domain layer — use cases

```dart
// features/finance/lib/src/domain/use_cases/get_accounts_use_case.dart
import 'package:application/application.dart';
import 'package:platform_core/result/result.dart';
import '../entities/account.dart';
import '../repositories/i_account_repository.dart';

final class GetAccountsUseCase
    implements NoParamsUseCase<Future<Result<List<Account>>>> {
  const GetAccountsUseCase(this._repository);
  final IAccountRepository _repository;

  @override
  Future<Result<List<Account>>> execute() => _repository.getAll();
}
```

For async operations with parameters use `AsyncUseCase<Input, Output>`:

```dart
final class GetAccountByIdUseCase
    implements AsyncUseCase<String, Account> {
  const GetAccountByIdUseCase(this._repository);
  final IAccountRepository _repository;

  @override
  Future<Result<Account>> execute(String id) => _repository.getById(id);
}
```

---

## Startup steps

```dart
// features/finance/lib/src/startup/finance_storage_init_step.dart
import 'package:application/application.dart';

final class FinanceStorageInitStep implements StartupStep {
  @override
  String get name => 'finance-storage-init';

  @override
  Future<void> execute(StartupContext context) async {
    // Initialise finance-specific local storage, run migrations, etc.
  }
}
```

---

## Public barrel

```dart
// features/finance/lib/finance.dart
library;

// DI
export 'src/di/finance_module.dart';

// Domain entities (only if other packages need them — e.g. shared widgets)
// Keep this list minimal; domain types are usually internal.
export 'src/domain/entities/account.dart';

// Routes (so apps/mobile can build GoRouter entries)
export 'src/routes/finance_routes.dart';
```

Feature packages export **only** what external callers (the app shell or tests)
need. Domain repositories and use-case implementations are internal.

---

## Registration in apps/mobile

```dart
// apps/mobile/lib/app/bootstrap/app_bootstrap.dart
final bootstrap = RuntimeBootstrap()
  ..addModule(AppModule())
  ..addModule(ApplicationModule())   // ← always first
  ..addModule(FinanceModule())       // ← feature modules after
  ..addModule(TasksModule());

await bootstrap.boot();
```

---

## FeatureModule lifecycle hooks

```
register()     — synchronous DI binding + route + startup-step registration
  └─ onInit()  — async: open feature storage, load feature config
      └─ onStart() — async: begin feature background work
          │
          │  (app is running)
          │
      onStop()     — async: stop background work
  └─ onDispose()   — async: close file handles, free resources
```

Override only the hooks your feature needs. `registerServices`,
`registerRoutes`, and `startupSteps` cover the common cases without needing
to override `register()` directly.

---

## Testing expectations

### Module test (required)

Every feature must have a `[feature_name]_module_test.dart` that:

1. Creates a `ServiceRegistry` with `ApplicationModule` registered.
2. Calls `FeatureModule.register()` on the feature module.
3. Asserts:
   - Metadata is in `FeatureRegistry`.
   - All expected routes are in `RouteRegistry`.
   - All expected startup steps are in `StartupPipeline`.
   - All expected services are registered in the locator.

```dart
// features/finance/test/di/finance_module_test.dart
import 'package:application/application.dart';
import 'package:feature_finance/finance.dart';
import 'package:platform_runtime/registry/service_registry.dart';
import 'package:test/test.dart';

void main() {
  late ServiceRegistry registry;

  setUp(() {
    registry = ServiceRegistry();
    ApplicationModule().register(registry);
    const FinanceModule().register(registry);
  });

  test('metadata registered', () {
    expect(registry.get<FeatureRegistry>().isRegistered('finance'), isTrue);
  });

  test('root route registered', () {
    expect(registry.get<RouteRegistry>().containsPath('/finance'), isTrue);
  });

  test('startup step added', () {
    final steps = registry.get<StartupPipeline>().steps;
    expect(steps.map((s) => s.name), contains('finance-storage-init'));
  });
}
```

### Domain tests (required)

Unit-test every use case with a mock or fake repository. No DI, no platform
packages needed — use cases are plain Dart.

### Data layer tests (required where storage exists)

Test repository implementations against an in-memory or file-backed store.

---

## Dependency validation checklist

Before merging a new feature package, verify:

- [ ] `pubspec.yaml` lists only `application` (and optionally `shared`) as project dependencies
- [ ] No import of `platform_runtime` or `platform_core` directly in feature source files
- [ ] No import of another `feature_*` package
- [ ] `FeatureModule` extends `FeatureModule` (not `RuntimeModule` directly)
- [ ] Routes defined as `const RouteDefinition` in a dedicated routes file
- [ ] Barrel exports only public API
- [ ] `[feature_name]_module_test.dart` present and passing
- [ ] Domain use cases unit-tested

---

## Naming conventions

| Artifact | Convention | Example |
|---|---|---|
| Package | `feature_[name]` | `feature_finance` |
| Folder | `features/[name]/` | `features/finance/` |
| Module class | `[Name]Module` | `FinanceModule` |
| Routes class | `[Name]Routes` | `FinanceRoutes` |
| Feature id | lowercase kebab | `'finance'` |
| Route path | `/[name]/…` | `'/finance/accounts'` |
| Route name | camelCase | `'financeAccounts'` |
| Barrel | `[name].dart` | `finance.dart` |

---

## What a feature must NOT do

- Import another feature package
- Import `platform_runtime` or `platform_core` directly in non-bootstrap code
- Put business logic in the DI module
- Export internal repository implementations or data models
- Depend on `go_router` directly — use `NavigationService` from `application`
- Build Flutter widget bindings against `AsyncState<T>` until ADR-004 is approved
