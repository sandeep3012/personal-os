import 'package:application/application.dart';

/// Route definitions for the Assets feature. Mirrors `NotesRoutes`.
///
/// Register these in [AssetsModule.registerRoutes] so [RouteRegistry]
/// tracks them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class AssetsRoutes {
  /// The feature root — entry point shown by [AssetsPage].
  static const root = RouteDefinition(
    path: '/assets',
    name: 'assets',
  );
}
