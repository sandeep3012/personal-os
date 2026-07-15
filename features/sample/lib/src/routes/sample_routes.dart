import 'package:application/application.dart';

/// Route definitions for the Sample feature.
///
/// Register [root] in [SampleModule.registerRoutes] so [RouteRegistry] tracks
/// it. The app layer ([apps/mobile]) uses these constants to build the matching
/// [GoRoute] entries for go_router.
abstract final class SampleRoutes {
  /// The feature root — entry point shown by [SamplePage].
  static const root = RouteDefinition(
    path: '/sample',
    name: 'sample',
  );
}
