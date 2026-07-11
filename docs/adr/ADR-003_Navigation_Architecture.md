# ADR-003 — Navigation Architecture

**ADR ID:** ADR-003
**Title:** Define Relationship Between ApplicationRouter, RouteRegistry, NavigationService, AppRouter, and go_router
**Status:** Accepted
**Date:** 2026-07-11
**Approved:** 2026-07-11
**Author:** Architecture Review
**Related Documents:** DOC-018, DOC-022, ADR-001

---

## Context

DOC-018 establishes the navigation intent:

> "Feature Packages register routes but do not control global navigation."
> "Platform owns top-level navigation while Feature Packages own internal navigation."

Sprint 5 created `AppRouter` in `apps/mobile` using go_router. Sprint 6 created `RouteRegistry`, `ApplicationRouter`, `NavigationService`, and `RouteDefinition` in `packages/application`.

These two surfaces had overlapping routing concerns with no defined relationship. Feature packages in Sprint 7 need to register and navigate to routes. Without a defined contract, each feature would make its own assumptions.

**DeepLink status:** `DeepLink` and `DeepLinkHandler` were implemented in Sprint 6 but have been removed from `packages/application` at v0.6.0. Deep link support is deferred to `platform_services` (future sprint). No feature package may implement deep link handling until that package exists and a separate ADR is approved.

---

## Decision

### Section 1 — Layer Responsibilities (Approved)

| Layer | Component | Responsibility |
|---|---|---|
| `packages/application` | `RouteDefinition` | Immutable value object carrying path + name |
| `packages/application` | `RouteRegistry` | Platform-independent catalog of all registered routes |
| `packages/application` | `ApplicationRouter` | Platform-independent resolver — converts path/name to RouteDefinition |
| `packages/application` | `NavigationService` | Abstract contract for navigation commands |
| `apps/mobile` | `AppRouter` | Concrete bridge: reads RouteRegistry; implements NavigationService backed by go_router |
| `apps/mobile` | go_router | Flutter routing engine — implementation detail of the Apps layer |

`ApplicationRouter` and `RouteRegistry` are NOT Flutter concepts. They are platform-independent. `AppRouter` bridges them to go_router.

Feature packages never import go_router. They import `packages/application` only.

---

### Section 2 — Route Registration Flow (Approved)

```
Boot sequence:
  1. AppBootstrap creates RuntimeBootstrap
  2. RuntimeBootstrap.addModule(AppModule())           // registers ILogger, AppConfig
  3. RuntimeBootstrap.addModule(ApplicationModule())   // registers RouteRegistry, ApplicationRouter, StartupPipeline, IEventBus
  4. RuntimeBootstrap.addModule(FeatureAModule())      // calls RouteRegistry.register(RouteDefinition(path: '/feature-a', name: 'featureA'))
  5. RuntimeBootstrap.addModule(FeatureBModule())      // registers its routes
  6. RuntimeBootstrap.boot()                           // register → onInit → onStart for all modules
  7. AppRouter reads RouteRegistry.routes and builds GoRoute list
  8. NavigationService registered into ServiceRegistry pointing to AppRouter instance
```

This satisfies DOC-018: "Feature Packages register routes but do not control global navigation."

---

### Section 3 — NavigationService Usage in Feature Use Cases (Approved)

Feature use cases that need to trigger navigation retrieve `NavigationService` from the `IServiceLocator`:

```dart
// In a feature use case:
final nav = locator.get<NavigationService>();
await nav.navigateTo(RouteConstants.dashboard);
```

The concrete implementation (`AppRouter` or a test double) is injected at startup. Feature packages never import `AppRouter` or go_router.

---

### Section 4 — AppRouter Responsibilities in Sprint 7 (Approved)

`AppRouter` in `apps/mobile` must be updated in Sprint 7 to:

1. Accept `RouteRegistry` as a constructor dependency (injected at startup)
2. Build its `GoRoute` list from `RouteRegistry.routes` rather than from hardcoded `RouteConstants`
3. Implement `NavigationService` and register itself in the ServiceRegistry during AppModule
4. Continue using go_router as the underlying routing engine

This is a Sprint 7 task. `AppRouter` does not need to change before Sprint 7 begins.

---

### Section 5 — Feature Route Registration Timing (Approved: Synchronous)

**Decision:** Feature modules register routes **synchronously during the `register()` phase**.

```dart
class FinanceModule extends RuntimeModule {
  @override
  void register(IDependencyRegistrar registrar) {
    final registry = registrar.get<RouteRegistry>(); // requires ApplicationModule registered first
    registry.register(const RouteDefinition(path: '/finance', name: 'finance'));
  }
}
```

**Rationale:**
- Simple and deterministic — all routes are known before any async work starts
- `AppRouter` can read the registry synchronously at boot
- No requirement for conditional routing at v0.7.0 (Product Owner confirmed)
- Conditional routing (feature-flag-gated routes) is deferred to a future ADR if needed

**Module ordering constraint:** `ApplicationModule` must always be added to `RuntimeBootstrap` before any feature module, so that `RouteRegistry` is available in the service locator when feature modules call `register()`.

---

### Section 6 — DeepLink Support (Deferred)

**Decision:** Deep link support is removed from `packages/application` and deferred to `platform_services`.

`DeepLink` and `DeepLinkHandler` were removed from `packages/application` at v0.6.0. No feature package may implement deep link handling until a future ADR establishes the `platform_services` package and defines the deep link contract.

**Rationale:** Deep link routing will need to coordinate with push notifications and search results — capabilities planned for `platform_services`. Committing to a deep link contract before that package exists would require a breaking migration when `platform_services` is introduced.

---

## Alternatives Considered

### Alternative A — Let apps/mobile own all routing (no RouteRegistry)

Rejected. DOC-018 requires Feature Packages to register routes without knowing about the app shell. A hardcoded route list in AppRouter cannot scale to independent feature packages.

### Alternative B — Feature packages import go_router directly

Rejected. go_router is a Flutter dependency. Feature packages must remain Flutter-independent per DOC-003 (Platform SDK Design Rules) and Package_Dependency_Matrix.md.

### Alternative C — ApplicationRouter replaces AppRouter entirely

Rejected. `ApplicationRouter` is a platform-independent resolver. It has no concept of Flutter navigation stacks, transitions, or back-button handling. `AppRouter` remains the concrete host.

### Alternative D — Async route registration (onInit phase)

Considered as Option B in the draft. Rejected for v0.7.0. Synchronous registration is sufficient and simpler. Async/conditional routing can be added via ADR if the product requires it.

---

## Consequences

### Positive

- Feature packages register routes without knowledge of go_router
- `NavigationService` provides a testable navigation contract for use-case testing
- The two routing surfaces (Sprint 5 AppRouter, Sprint 6 RouteRegistry) have a defined, non-overlapping relationship
- DOC-018 intent is fully satisfied
- No premature deep link commitment — contract stays correct when platform_services arrives

### Negative / Risks

- `AppRouter` must be refactored in Sprint 7 to read from `RouteRegistry` (currently hardcoded to `RouteConstants`)
- `RouteRegistry` and `ApplicationModule` registration order creates a module dependency: `ApplicationModule` must boot before any feature module
- Deep link support unavailable until `platform_services` sprint

---

## Actions Completed at v0.6.0

- [x] Defined layer responsibilities (Section 1)
- [x] Defined route registration flow (Section 2)
- [x] Approved synchronous route registration timing (Section 5)
- [x] Removed `DeepLink` and `DeepLinkHandler` from `packages/application` (Section 6)

## Actions Required in Sprint 7

- [ ] Refactor `AppRouter` to read from `RouteRegistry` and implement `NavigationService`
- [ ] Ensure `ApplicationModule` is always added before feature modules in `AppBootstrap`
- [ ] Update `RouteConstants` usage — routes should come from `RouteRegistry`, not hardcoded strings
