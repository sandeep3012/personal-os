import 'package:application/application.dart';

/// Route definitions for the Calendar feature. Mirrors `NotesRoutes`.
///
/// Register these in [CalendarModule.registerRoutes] so [RouteRegistry]
/// tracks them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class CalendarRoutes {
  /// The feature root — entry point shown by [CalendarPage].
  static const root = RouteDefinition(
    path: '/calendar',
    name: 'calendar',
  );
}
