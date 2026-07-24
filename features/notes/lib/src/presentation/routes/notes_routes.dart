import 'package:application/application.dart';

/// Route definitions for the Notes feature. Mirrors `GoalsRoutes`.
///
/// Register these in [NotesModule.registerRoutes] so [RouteRegistry] tracks
/// them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class NotesRoutes {
  /// The feature root — entry point shown by [NotesPage].
  static const root = RouteDefinition(
    path: '/notes',
    name: 'notes',
  );
}
