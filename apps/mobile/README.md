# apps/mobile

Personal OS Flutter application — the composition root for all platforms
(Android, iOS, Web, Windows, macOS, Linux).

---

## Responsibilities

`apps/mobile` is the **application shell**. It:

- Initialises the platform runtime via `AppBootstrap`
- Registers application-level services via `AppModule`
- Hosts top-level navigation via `AppRouter` (go_router)
- Composes feature packages (future sprints)
- Contains no business logic

---

## Structure

```
lib/
├── main.dart                       # Flutter entry point
└── app/
    ├── app.dart                    # PersonalOsApp widget (MaterialApp.router)
    ├── bootstrap/
    │   ├── app_bootstrap.dart      # Boot / shutdown orchestration
    │   └── app_module.dart         # AppConfig + ILogger DI registration
    ├── navigation/
    │   └── app_router.dart         # go_router configuration
    ├── screens/
    │   └── home/
    │       └── home_screen.dart    # Platform status screen (Sprint 5)
    ├── theme/
    │   └── app_theme.dart          # Light + dark MaterialTheme
    └── widgets/
        ├── section_card.dart
        └── status_item.dart
```

---

## Bootstrap Flow

```
main()
  └─ WidgetsFlutterBinding.ensureInitialized()
  └─ AppBootstrap.boot()
      └─ RuntimeBootstrap
          ├─ AppModule.register()    — binds ILogger, AppConfig
          ├─ AppModule.onInit()      — no-op (Sprint 5)
          └─ AppModule.onStart()     — no-op (Sprint 5)
  └─ runApp(PersonalOsApp)
```

On boot failure, `BootFailureApp` is shown with an error message and a
retry button.

---

## Dependencies

| Dependency | Purpose | Allowed? |
|---|---|---|
| `application` | Use-case abstractions, navigation contracts | ✅ Approved |
| `flutter` | UI framework | ✅ Required |
| `go_router` | Concrete routing engine | ✅ Apps layer |
| `platform_core` | AppConfig, ILogger, IDependencyRegistrar | ⚠️ Direct import — see note |
| `platform_runtime` | RuntimeBootstrap, RuntimeModule | ⚠️ Direct import — see note |
| `platform_storage` | Storage contracts | ⚠️ Unused — remove when confirmed |

> **Note on direct platform imports:** `AppModule` extends `RuntimeModule`
> (platform_runtime) and registers `AppConfig` / `ILogger` (platform_core).
> Bootstrap code necessarily assembles all layers at the composition root.
> These imports are in scope for apps/mobile only. Feature packages must
> never import platform packages directly.
>
> Formal approval is tracked in ADR-001. Resolution options are documented
> in the Sprint 6 Readiness Audit (Phase 5).

---

## Running

```bash
# Install dependencies
dart pub global run melos bootstrap

# Run on connected device / simulator
cd apps/mobile
flutter run

# Web
flutter run -d chrome

# Analyze
flutter analyze

# Test
flutter test
```

---

## Version

`v0.6.0+1` — Application Layer Foundation
