# platform_core

Foundational types, patterns, and abstractions for the Personal OS monorepo.

---

## Purpose

`platform_core` is the lowest layer of the Personal OS dependency graph. Every
other package — `runtime`, `storage`, `features/*` — depends on it. It contains
zero business logic and has no dependency on Flutter UI, third-party packages,
or any other Personal OS package.

---

## Dependency Rule

```
Apps → Features → Platform SDK (this package) → Dart SDK
```

`platform_core` must **never** import from Runtime, Services, Features, or
Flutter UI packages.

---

## Public API

### Result Pattern

Discriminated union for fallible operations. Prefer `Result` over throwing
exceptions across layer boundaries.

```dart
import 'package:platform_core/result/result.dart';

Future<Result<User>> loadUser(String id) async {
  try {
    return Result.success(await api.fetch(id));
  } catch (e, st) {
    return Result.failure(UnknownException(message: e.toString(), cause: e, stackTrace: st));
  }
}

final result = await loadUser('123');
result.when(
  success: (user) => print(user.name),
  failure: (e)    => print(e.message),
);
```

### Exceptions

```dart
import 'package:platform_core/exceptions/exceptions.dart';

throw ValidationException(message: 'Email is required', field: 'email');
throw ConfigurationException(message: 'Missing API URL', key: 'apiBaseUrl');
throw UnknownException(message: 'Unexpected failure', cause: e);
```

### Logging

```dart
import 'package:platform_core/logging/logging.dart';

// Inject ILogger — never construct Logger directly in feature code.
final ILogger log = Logger(tag: 'AuthService', minimumLevel: LogLevel.debug);

log.info('User signed in');
log.error('Sign-in failed', error: e, stackTrace: st);

// Tests: use NoOpLogger.
final ILogger noOp = const NoOpLogger();
```

### Configuration & Environment

```dart
import 'package:platform_core/config/config.dart';
import 'package:platform_core/environment/environment.dart';

const config = AppConfig(
  appName: 'Personal OS',
  environment: BuildEnvironment.production,
  version: '1.0.0',
);

if (config.isDevelopment) { /* enable debug tools */ }
```

### Dependency Injection Abstractions

```dart
import 'package:platform_core/di/di.dart';

// In a feature module:
class AuthModule implements IModule {
  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(),
    );
  }
}

// In a use-case:
final repo = locator.get<AuthRepository>();
```

### Constants

```dart
import 'package:platform_core/constants/constants.dart';

print(AppConstants.appName);      // 'Personal OS'
print(StorageKeys.themeMode);     // 'app.theme_mode'
print(RouteConstants.dashboard);  // '/dashboard'
```

### Extensions

```dart
import 'package:platform_core/extensions/extensions.dart';

'hello world'.capitalised;              // 'Hello world'
'build_env'.toTitleCase();             // 'Build Env'
'  '.isBlank;                          // true
[1, 2, 1, 3].distinct();               // [1, 2, 3]
DateTime(2024, 6, 15).isWeekend;       // true (Saturday)
```

### Utilities

```dart
import 'package:platform_core/utils/utils.dart';

final id = const UuidGenerator().generate();
// 'a1b2c3d4-e5f6-4789-8abc-def012345678'

ValidationHelpers.email('bad');         // 'Enter a valid email.'
ValidationHelpers.required(null);       // 'Field is required.'
DateHelpers.daysBetween(from, to);
```

---

## Types

```dart
import 'package:platform_core/types/types.dart';

typedef AppId         = String;
typedef FutureResult<T> = Future<Result<T>>;
```

---

## Running Tests

```bash
cd packages/platform_core
dart test
```
