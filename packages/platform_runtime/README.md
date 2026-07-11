# platform_runtime

Personal OS Platform Runtime — event bus, service registry, module system,
lifecycle management, and bootstrap orchestration.

Pure Dart package. No Flutter dependency.

---

## Responsibilities

`platform_runtime` provides the live execution infrastructure of Personal OS:

| Area | What it provides |
|---|---|
| **Bootstrap** | `RuntimeBootstrap` — ordered module startup and shutdown |
| **Modules** | `RuntimeModule` — base class for all runtime service modules |
| **Service Registry** | `ServiceRegistry` — in-memory DI container |
| **Event Bus** | `IEventBus` / `EventBus` — publish/subscribe event distribution |
| **Lifecycle** | `LifecycleManager` / `LifecycleObserver` — state machine lifecycle |
| **Exceptions** | `RuntimeException`, `LifecycleException`, `RegistryException` |

**Explicitly excluded** from this package:

- Business logic of any kind
- Feature-specific services
- Flutter UI code
- Storage implementations
- AI, Search, Timeline, or Notification engines

---

## Dependency Graph

```
Apps
 └─ Features
     └─ application
         └─ platform_runtime   ← this package
             └─ platform_core  (Result, AppException, IModule, ILogger, …)
```

`platform_runtime` must **never** depend on:
- Feature packages
- `apps/*`
- Flutter SDK packages

---

## Public API

```dart
import 'package:platform_runtime/platform_runtime.dart';
```

---

### Bootstrap

`RuntimeBootstrap` orchestrates the startup and shutdown of all modules.

```dart
final bootstrap = RuntimeBootstrap();
bootstrap
  ..addModule(AppModule())         // must be added before boot()
  ..addModule(ApplicationModule())
  ..addModule(FinanceModule());

await bootstrap.boot();
// app is running …
await bootstrap.shutdown();
```

**Startup sequence** (per module, in registration order):

```
register(registrar)   // synchronous DI binding
  → onInit()          // async — open connections, read config
      → onStart()     // async — begin background work
```

**Shutdown sequence** (reverse registration order):

```
onStop()    // async — graceful stop
  → onDispose()  // async — release resources
```

`boot()` and `shutdown()` are idempotent — calling either more than once
throws `RuntimeException`.

---

### RuntimeModule

The extension point for all platform and feature services.

```dart
class DatabaseModule extends RuntimeModule {
  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerLazySingleton<IDatabase>(() => SqliteDatabase());
  }

  @override
  Future<void> onInit() async {
    final db = locator.get<IDatabase>();
    await db.open();
  }

  @override
  Future<void> onDispose() async {
    await locator.get<IDatabase>().close();
  }
}
```

Override only the hooks you need. All hooks default to no-ops.

---

### ServiceRegistry

In-memory DI container implementing both `IDependencyRegistrar` and
`IServiceLocator` from `platform_core`.

```dart
final registry = ServiceRegistry();

// Registration modes:
registry.registerSingleton<ILogger>(Logger(tag: 'App'));     // pre-created
registry.registerFactory<ITransaction>(() => Transaction()); // new on each get
registry.registerLazySingleton<IEventBus>(() => EventBus()); // created once on first get

// Resolution:
final logger = registry.get<ILogger>();
final isRegistered = registry.isRegistered<ILogger>(); // true

// Test utilities:
registry.unregister<ILogger>();  // remove one registration
registry.reset();                 // clear all (test tear-down)
```

Throws `RegistryException` if a type is not registered or is registered twice.

---

### Event Bus

```dart
final IEventBus bus = EventBus();

// Subscribe to a specific event type:
final sub = bus.subscribe<UserLoggedInEvent>((event) {
  print('User logged in: ${event.userId}');
});

// Subscribe to all events:
final allSub = bus.subscribeToAll((event) {
  print('Event: ${event.runtimeType}');
});

// Publish:
bus.publish(UserLoggedInEvent(userId: 'abc123'));

// Cancel subscription:
sub.cancel();

// Dispose when done:
bus.dispose();
```

Events must extend `IEvent`. By convention (DOC-006), use past-tense names:
`ExpenseCreated`, `TaskCompleted`, `WorkspaceActivated`.

---

### Lifecycle

```dart
class MyObserver implements LifecycleObserver {
  @override
  Future<void> onInitialize() async { /* cold start */ }

  @override
  Future<void> onStart() async { /* become active */ }

  @override
  Future<void> onPause() async { /* going to background */ }

  @override
  Future<void> onResume() async { /* returning to foreground */ }

  @override
  Future<void> onStop() async { /* stopping */ }

  @override
  Future<void> onDispose() async { /* final cleanup */ }
}

final manager = LifecycleManager();
manager.addObserver(MyObserver());
await manager.initialize();
await manager.start();
// …
await manager.stop();
await manager.dispose();
```

`LifecycleManager` enforces valid state transitions and throws
`LifecycleException` on illegal transitions.

---

## Package Boundaries

| Package | May import `platform_runtime`? |
|---|---|
| `platform_core` | No (platform_runtime depends on platform_core, not the reverse) |
| `platform_storage` | No |
| `application` | Yes — uses IEventBus, RuntimeModule, LifecycleObserver |
| Feature packages | Conditional — only through approved abstractions in `application` |
| `apps/mobile` | Yes — uses RuntimeBootstrap directly for application bootstrap |

---

## Running Tests

```bash
cd packages/platform_runtime
dart test
```
