/// Sample Feature — Feature Framework reference implementation.
///
/// This package is NOT a business feature. It exists solely to validate the
/// Personal OS Feature Framework end-to-end before the first real feature
/// (Finance) is implemented in Sprint 8.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_sample/sample.dart';
/// ```
///
/// - [SampleModule] — register with [RuntimeBootstrap]
/// - [SampleRoutes] — route path/name constants for go_router wiring
/// - [SamplePage] — Flutter screen widget
/// - [SampleService] — resolved from DI for page construction
/// - [GetSampleStatusUseCase] — resolved from DI for use-case testing
library;

// Application service
export 'src/application/sample_service.dart';

// DI
export 'src/di/sample_module.dart';

// Domain — use cases
export 'src/domain/use_cases/get_sample_status_use_case.dart';

// Presentation
export 'src/presentation/pages/sample_page.dart';

// Routes
export 'src/routes/sample_routes.dart';
