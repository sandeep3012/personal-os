## 0.1.0

* Initial Platform Core implementation (Sprint 2).
* Result pattern: `Result<T>`, `Success<T>`, `Failure<T>` with `map`, `flatMap`, `when`.
* Exception hierarchy: `AppException`, `ValidationException`, `ConfigurationException`, `UnknownException`.
* Logging: `ILogger` interface, `Logger` (dart:developer backed), `NoOpLogger`, `LogLevel` enum.
* Configuration: `AppConfig` value object, `BuildEnvironment` enum with convenience extensions.
* DI abstractions: `IServiceLocator`, `IDependencyRegistrar`, `IModule` interfaces.
* Constants: `AppConstants`, `StorageKeys`, `RouteConstants`.
* Extensions: `StringX`, `IterableX`, `DateTimeX`.
* Types: `VoidCallback`, `AsyncCallback`, `AppResult<T>`, `FutureResult<T>`, `AppId`.
* Utilities: `UuidGenerator`, `DateHelpers`, `ValidationHelpers`.
