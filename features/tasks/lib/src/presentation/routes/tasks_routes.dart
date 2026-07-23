import 'package:application/application.dart';

/// Route definitions for the Tasks feature. Mirrors `FinanceRoutes`.
///
/// Register these in [TasksModule.registerRoutes] so [RouteRegistry] tracks
/// them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class TasksRoutes {
  /// The feature root — entry point shown by [TasksPage].
  static const root = RouteDefinition(
    path: '/tasks',
    name: 'tasks',
  );
}
