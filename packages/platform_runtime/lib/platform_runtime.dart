/// Personal OS Platform Runtime
///
/// Provides the event bus, service registry, module system, lifecycle
/// management, and bootstrap orchestration for the Personal OS application.
///
/// ## Architecture
///
/// ```
/// Apps → Features → platform_runtime → platform_core
/// ```
///
/// `platform_runtime` depends exclusively on `platform_core` — it never
/// imports Flutter SDK packages or feature-layer packages.
///
/// ## Public API
///
/// ```dart
/// import 'package:platform_runtime/platform_runtime.dart';
/// ```
library;

// Bootstrap
export 'package:platform_runtime/bootstrap/bootstrap_barrel.dart';

// Event Bus
export 'package:platform_runtime/event_bus/event_bus_barrel.dart';

// Lifecycle
export 'package:platform_runtime/lifecycle/lifecycle_barrel.dart';

// Modules
export 'package:platform_runtime/modules/modules_barrel.dart';

// Service Registry
export 'package:platform_runtime/registry/registry_barrel.dart';
