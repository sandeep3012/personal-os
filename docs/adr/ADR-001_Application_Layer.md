# ADR-001 — Application Layer

**ADR ID:** ADR-001
**Title:** Establish packages/application as an Official Platform Layer
**Status:** Accepted
**Date:** 2026-07-11
**Approved:** 2026-07-11
**Author:** Architecture Review
**Related Documents:** DOC-003, DOC-004, DOC-006, DOC-018, DOC-022, DOC-023, Package_Dependency_Matrix

---

## Context

The Personal OS dependency chain (MASTER_CONTEXT.md, Package_Dependency_Matrix.md) names an `Application` layer positioned between Feature packages and the Platform Runtime:

```
Apps → Features → Application → Platform Runtime → Platform Core
```

This layer was referenced in governance documents as a Sprint 6 deliverable but was absent from two architecture documents:

- **DOC-022** (Monorepo Architecture) — packages/ list did not include `application`
- **DOC-027** (Repository Bootstrap Specification) — packages/ layout did not include `application`

Sprint 6 created `packages/application` without a preceding ADR, violating the ADR trigger rule defined in Package_Dependency_Matrix.md:

> "A new ADR is required when: Introducing a new Platform package."

This ADR retroactively formalizes the decision and defines the boundaries of the Application layer so that Sprint 7 feature packages have a stable foundation to depend on.

---

## Decision

**Establish `packages/application` as an official Platform SDK package.**

The Application package is the orchestration layer. It provides reusable abstractions that Feature packages depend on for implementing their use-case, navigation, validation, and messaging concerns.

### Dependency Position

```
apps/*
   ↓
features/*
   ↓
application          ← this package
   ↓
platform_runtime
   ↓
platform_core
```

### Approved Responsibilities (Product Owner Approved)

The Application layer owns the following — no more, no less:

| Subsystem | Types | Architectural Basis |
|---|---|---|
| Use Cases | `UseCase<I,O>`, `AsyncUseCase<I,O>`, `NoParamsUseCase<O>` | Clean Architecture (DOC-023) |
| Application services | `AppLifecycleService` | Lifecycle orchestration above RuntimeBootstrap |
| Navigation contracts | `NavigationService`, `RouteDefinition`, `RouteRegistry`, `ApplicationRouter` | DOC-018: feature packages register routes |
| Validation framework | `Validator<T>`, `ValidationResult`, `ValidationFailure`, `CompositeValidator<T>` | DOC-023; distinct from Flutter form validators |
| Domain event markers | `AppEvent`, `DomainEvent` | DOC-006: named event categories |
| Application exceptions | `NavigationException`, `UseCaseException`, `PermissionException` | Follows AppException subclassing pattern |
| DI module | `ApplicationModule extends RuntimeModule` | Approved DI extension point |
| Feature flags | `FeatureFlag`, `FeatureFlagService` | Interface-only; implementations in apps/* |
| Permissions | `PermissionService`, `PermissionType`, `PermissionStatus` | Provisional — see table below |
| Startup pipeline | `StartupPipeline`, `StartupContext`, `StartupStep` | Application Startup Pipeline tier — see Startup Hierarchy |
| Domain state type | `AsyncState<T>` | Approved as pure Dart domain type only (see ADR-002) |

### Application Must NOT Own

- Flutter UI or presentation concerns
- Platform implementations (EventBus, ServiceRegistry, RuntimeBootstrap)
- Utilities already in Platform Core
- Business logic of any domain

### Startup Hierarchy (Approved)

The approved three-tier startup model:

```
RuntimeBootstrap          (platform_runtime — infrastructure)
   Owns: ServiceRegistry, EventBus, module lifecycle, boot sequencing
    ↓
StartupPipeline           (application — orchestration)
   Owns: ordered execution of feature startup tasks
    ↓
StartupStep impls         (features — business startup tasks)
   Own: per-feature initialisation (storage, analytics, config, etc.)
```

`RuntimeBootstrap` drives infrastructure. `StartupPipeline` (registered by `ApplicationModule`) is invoked during the `onStart` phase to orchestrate application-level feature tasks. Feature packages implement `StartupStep`.

### Items Resolved at v0.6.0

| Item | Resolution |
|---|---|
| `AsyncState<T>`, `LoadingState`, `SuccessState`, `ErrorState` | **Approved** as pure Dart domain state type. UI framework binding deferred to ADR-004. |
| `DeepLink`, `DeepLinkHandler` | **Removed** from packages/application. Deferred to platform_services. See ADR-003. |
| `PermissionService`, `PermissionType`, `PermissionStatus`, `PermissionException` | **Provisional** — documented as such; no feature packages may depend on these until resolved. |
| `AppLifecycleService` | **Provisional** — retained; requires justification ADR before Sprint 7 feature use. |
| `FeatureFlag`, `FeatureFlagService` | **Approved** as interface-only. Implementations live in apps/*. |
| `AppConfiguration` | **Removed** — redundant with `AppConfig` in platform_core. |
| `BuildFlavor` | **Removed** — redundant with `BuildEnvironment` in platform_core. |
| `StartupPipeline`, `StartupContext`, `StartupStep` | **Approved** — Application Startup Pipeline tier (see Startup Hierarchy above). |

### Allowed Dependencies

```yaml
dependencies:
  platform_core: any       # always required
  platform_runtime: any    # always required
```

`platform_storage` is NOT a default dependency. Add only if storage contracts are required.

### Forbidden Dependencies

- `package:flutter/*` or any Flutter SDK package
- Feature packages
- `apps/*`

### Relationship with Platform Runtime

`platform_runtime` owns: the event bus implementation, the service registry, the module system, the lifecycle state machine, and bootstrap orchestration.

`application` consumes:
- `IEventBus` — publishes and subscribes to events via the runtime's EventBus
- `RuntimeModule` — extends it to register application-level services
- `LifecycleObserver` — `AppLifecycleService` delegates to it

`application` must NOT duplicate: `EventBus`, `ServiceRegistry`, `RuntimeBootstrap`, `LifecycleManager`.

### Relationship with Feature Packages

Feature packages depend on `application` for:
- Use-case interfaces to implement their domain use cases
- Navigation contracts to register and navigate to their routes
- Validation abstractions to validate domain inputs
- Event marker types to publish domain events

Feature packages must NOT depend on `platform_runtime` or `platform_core` directly unless explicitly approved by a separate ADR.

---

## Alternatives Considered

### Alternative A — Keep orchestration in platform_runtime

Rejected. `platform_runtime` is responsible for infrastructure (event bus, service registry, module lifecycle). Adding use-case interfaces, navigation abstractions, and validation frameworks to it would make it a monolithic dependency with mixed responsibilities.

### Alternative B — Let each Feature package define its own use-case interfaces

Rejected. Each feature would define incompatible `UseCase` interfaces, preventing consistent cross-feature tooling, testing patterns, or shared middleware.

### Alternative C — Put orchestration in shared/

Rejected. `shared/` is defined in DOC-022 as containing UI components, themes, localization, and assets — presentation-layer concerns. Orchestration logic belongs in a platform package, not a UI package.

---

## Consequences

### Positive

- Feature packages have a single, consistent use-case interface.
- Navigation abstraction enables platform-independent route management.
- Validation framework is reusable across all features without duplication.
- `ApplicationModule` provides a structured DI extension point for application-level services.
- The dependency chain is now fully named and documented.
- Startup hierarchy is explicit — no ambiguity about which layer orchestrates what.

### Negative / Risks

- The Application layer adds a dependency hop between Feature packages and the Platform Runtime.
- Provisional items (`PermissionService`, `AppLifecycleService`) must be resolved before Sprint 7 feature packages may use them.
- `AppRouter` (apps/mobile) and `RouteRegistry` / `ApplicationRouter` (application) have overlapping routing concerns — resolved in ADR-003.

---

## Bootstrap Exception — apps/mobile Direct Platform Imports

`apps/mobile` imports `platform_core` and `platform_runtime` directly in bootstrap files:

| File | Imports |
|---|---|
| `app_bootstrap.dart` | `RuntimeBootstrap`, `AppConfig`, `IServiceLocator`, `ILogger` |
| `app_module.dart` | `RuntimeModule`, `AppConfig`, `IDependencyRegistrar`, `BuildEnvironment`, `Logger`, `ILogger` |
| `app_router.dart` | `AppConfig` |

This is a controlled exception to the rule "Apps never access Platform directly."

**Approval:** These imports are explicitly approved for bootstrap/composition-root files in `apps/mobile/lib/app/bootstrap/` and `apps/mobile/lib/app/navigation/` only.

**Rationale:** Bootstrap code is the composition root. It is the one location that necessarily assembles all layers. Moving this code to `application` would turn that package into a re-export proxy (contrary to its orchestration role). The exception is narrow, documented, and does not affect feature packages.

**Constraint:** This approval is ONLY for the named files. No feature package, no screen code, and no use-case may use this exception to bypass the dependency rule.

---

## Actions Completed at v0.6.0

- [x] Updated DOC-022 (Monorepo Architecture) — `application` added to packages/ list
- [x] Updated DOC-027 (Repository Bootstrap Specification) — `application` added to repository layout
- [x] Removed `BuildFlavor`, `AppConfiguration`, `DeepLink`, `DeepLinkHandler` from packages/application
- [x] Approved `AsyncState<T>` as domain state type (ADR-002 updated)
- [x] Resolved route registration timing (ADR-003 Section 5 — synchronous, approved)
- [x] Defined startup hierarchy (RuntimeBootstrap → StartupPipeline → StartupStep)

## Actions Required Before Sprint 7

- [ ] Resolve provisional status of `PermissionService` (conflicts with DOC-003 Core Layer placement)
- [ ] Resolve provisional status of `AppLifecycleService` (requires justification vs. platform_runtime ownership)
- [ ] Approve ADR-004 (state management framework selection — UI binding layer)
