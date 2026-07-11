/// Personal OS — Application Layer Foundation
///
/// The orchestration layer between Feature packages and the Platform Runtime.
/// Provides use-case interfaces, navigation contracts, validation framework,
/// domain event markers, permission abstractions, lifecycle hooks, and
/// feature flag interfaces.
///
/// ## Architecture position
///
/// ```
/// Apps
///  ↓
/// Features
///  ↓
/// application          ← this package
///  ↓
/// platform_runtime
///  ↓
/// platform_core
/// ```
///
/// ## Startup hierarchy
///
/// ```
/// RuntimeBootstrap          (platform_runtime — infrastructure)
///  ↓
/// StartupPipeline           (application — orchestration)
///  ↓
/// StartupStep impls         (features — business startup tasks)
/// ```
///
/// ## What this package IS
///
/// - Use-case base interfaces
/// - Navigation contracts (RouteRegistry, NavigationService)
/// - Validation framework (`Validator<T>`, `ValidationResult`)
/// - Domain event marker types (DomainEvent, AppEvent)
/// - Permission abstractions (PermissionService — provisional)
/// - Feature flag interfaces (FeatureFlagService — provisional)
/// - Lifecycle hook (AppLifecycleService — provisional)
/// - Application-layer DI module (ApplicationModule)
///
/// ## What this package IS NOT
///
/// - A UI framework
/// - Another utility SDK
/// - A re-export proxy for platform packages
/// - Business logic of any kind
///
/// ## Public API
///
/// ```dart
/// import 'package:application/application.dart';
/// ```
library;

// Configuration — feature flag interfaces only
// (BuildFlavor and AppConfiguration removed: redundant with platform_core types)
export 'src/configuration/feature_flag.dart';
export 'src/configuration/feature_flag_service.dart';

// DI
export 'src/di/application_module.dart';

// Errors
export 'src/errors/navigation_exception.dart';
export 'src/errors/permission_exception.dart';
export 'src/errors/use_case_exception.dart';

// Lifecycle (provisional — see ADR-001)
export 'src/lifecycle/app_lifecycle_service.dart';

// Messaging
export 'src/messaging/app_event.dart';
export 'src/messaging/domain_event.dart';

// Navigation
// DeepLink removed — deferred to platform_services (see ADR-003)
export 'src/navigation/application_router.dart';
export 'src/navigation/navigation_service.dart';

// Permissions (provisional — see ADR-001)
export 'src/permissions/permission_service.dart';
export 'src/permissions/permission_status.dart';
export 'src/permissions/permission_type.dart';

// Routing
export 'src/routing/route_definition.dart';
export 'src/routing/route_registry.dart';

// Startup
export 'src/startup/startup_context.dart';
export 'src/startup/startup_pipeline.dart';
export 'src/startup/startup_step.dart';

// State
// AsyncState<T> approved as domain state representation type (see ADR-002)
// UI framework binding deferred to ADR-004
export 'src/state/app_state.dart';
export 'src/state/async_state.dart';

// Use cases
export 'src/usecases/async_use_case.dart';
export 'src/usecases/no_params_use_case.dart';
export 'src/usecases/use_case.dart';

// Validation
export 'src/validation/composite_validator.dart';
export 'src/validation/validation_failure.dart';
export 'src/validation/validation_result.dart';
export 'src/validation/validator.dart';
