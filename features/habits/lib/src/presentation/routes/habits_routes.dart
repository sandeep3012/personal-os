import 'package:application/application.dart';

/// Route definitions for the Habits feature. Mirrors `FinanceRoutes`.
///
/// Register these in [HabitsModule.registerRoutes] so [RouteRegistry] tracks
/// them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class HabitsRoutes {
  /// The feature root — entry point shown by [HabitsPage].
  static const root = RouteDefinition(
    path: '/habits',
    name: 'habits',
  );
}
