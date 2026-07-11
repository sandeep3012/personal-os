# Dependency Analysis — v0.6.0

**Version:** v0.6.0-application-foundation
**Date:** 2026-07-11
**Purpose:** Documents the dependency direction question for apps/mobile and
determines whether the approved chain is achievable.

---

## Approved Chain (Package_Dependency_Matrix.md)

```
Apps → Features → Application → Platform Runtime → Platform Core
```

**Allowed for apps/mobile:** `feature_*, application, shared`
**Rule:** "Apps never access Platform directly unless explicitly approved."

---

## Current apps/mobile pubspec.yaml

```yaml
dependencies:
  application:       any    # ✅ approved
  flutter:           sdk    # ✅ required (Flutter app)
  cupertino_icons:   ^1.0   # ✅ UI asset
  go_router:         ^17.3  # ✅ routing engine (Apps layer, not project layer)
  platform_core:     any    # ⚠️ direct platform import
  platform_runtime:  any    # ⚠️ direct platform import
  platform_storage:  any    # ❌ unused — no imports found in source
```

---

## Why Direct Platform Imports Exist

### platform_core

Used in:

| File | Types Imported |
|---|---|
| `app_module.dart` | `AppConfig`, `IDependencyRegistrar`, `BuildEnvironment`, `Logger`, `ILogger` |
| `app_router.dart` | `AppConfig` |
| `app_bootstrap.dart` | `AppConfig`, `IServiceLocator`, `ILogger` |

`AppModule` extends `RuntimeModule` and registers `AppConfig` and `ILogger`. These
are core infrastructure types that the module must know at registration time.

### platform_runtime

Used in:

| File | Types Imported |
|---|---|
| `app_module.dart` | `RuntimeModule` |
| `app_bootstrap.dart` | `RuntimeBootstrap` |

`AppModule extends RuntimeModule` is the DI extension point. `AppBootstrap` creates
and drives `RuntimeBootstrap`. Bootstrap code is the composition root — it is
the one location in the codebase that necessarily knows all layers.

### platform_storage

**No source files in apps/mobile import from platform_storage.**
This dependency was added preemptively. It is safe to remove from pubspec.yaml
without any code change.

---

## Is the Approved Chain Achievable?

The question: can apps/mobile depend ONLY on `application` (not on
`platform_core` or `platform_runtime` directly)?

### Option A — Re-export Platform Types via application (Not Recommended)

Have `packages/application/lib/application.dart` re-export `RuntimeBootstrap`,
`AppConfig`, `IDependencyRegistrar`, etc. so apps/mobile imports them through
the `application` barrel.

**Problem:** This turns `application` into a pass-through proxy. Its role is
orchestration, not re-exporting every platform type. The Package_Dependency_Matrix
explicitly warns: "Application must not become another utility SDK."

**Verdict:** Architecturally wrong. Do not do this.

---

### Option B — Move AppBootstrap and AppModule into application (Future Sprint)

Move the composition-root bootstrap code from `apps/mobile` into
`packages/application`:

```
packages/application/lib/src/bootstrap/
  ├── default_app_config.dart    # const AppConfig for production
  └── personal_os_module.dart    # extends RuntimeModule, registers config + logger
```

Apps/mobile then only calls:
```dart
final bootstrap = RuntimeBootstrap()
  ..addModule(PersonalOsModule())
  ..addModule(ApplicationModule());
await bootstrap.boot();
```

Apps/mobile still needs `platform_runtime` for `RuntimeBootstrap` — but
`AppModule`-like registration moves to `application`.

**Problem:** This reduces the number of direct platform imports in apps/mobile
but does not eliminate them. `RuntimeBootstrap` is inherently a platform_runtime
type and must be composed at the app level.

**Verdict:** Reduces violations but does not fully resolve them. Appropriate
as a future refinement, not a requirement now.

---

### Option C — Explicit Approval (Recommended Resolution)

Formally approve apps/mobile's direct imports of `platform_core` and
`platform_runtime` for bootstrap purposes only.

**Rationale:**
- Bootstrap code is the composition root by definition
- The violations are confined to 3 files: `app_bootstrap.dart`, `app_module.dart`, `app_router.dart`
- No feature code imports platform packages — the boundary holds everywhere except the composition root
- DOC-001 Platform Constitution says: "New Apps should require minimal changes to existing Apps" — this is the boot code, not the feature code
- Package_Dependency_Matrix.md already has the escape hatch: "unless explicitly approved"

**Implementation:** ADR-001 Section "apps/mobile Bootstrap Exception" documents this approval.

**Constraint:** This approval applies ONLY to files in `apps/mobile/lib/app/bootstrap/` and `apps/mobile/lib/app/navigation/`. No feature-layer code may use this exception.

---

## Recommended Immediate Actions

1. **Remove `platform_storage: any`** from `apps/mobile/pubspec.yaml` — no source files import it.
2. **Add bootstrap exception to ADR-001** — explicitly approve `platform_core` and `platform_runtime` imports in apps/mobile bootstrap files.
3. **Do not refactor AppBootstrap/AppModule this sprint** — the violation is documented and approved; the refactor is optional for a future sprint.

---

## Summary

| Import | Status | Action |
|---|---|---|
| `application` | ✅ Correct | None |
| `flutter` | ✅ Required | None |
| `go_router` | ✅ App-layer technology | None |
| `platform_core` | ⚠️ Bootstrap-only; approve via ADR-001 | Document approval |
| `platform_runtime` | ⚠️ Bootstrap-only; approve via ADR-001 | Document approval |
| `platform_storage` | ❌ Unused | Remove from pubspec.yaml |
