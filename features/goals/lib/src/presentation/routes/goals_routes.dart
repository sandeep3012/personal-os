import 'package:application/application.dart';

/// Route definitions for the Goals feature. Mirrors `FinanceRoutes`.
///
/// Register these in [GoalsModule.registerRoutes] so [RouteRegistry] tracks
/// them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class GoalsRoutes {
  /// The feature root — entry point shown by [GoalsPage].
  static const root = RouteDefinition(
    path: '/goals',
    name: 'goals',
  );
}
