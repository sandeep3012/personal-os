import 'package:application/application.dart';

/// Route definitions for the Documents feature. Mirrors `NotesRoutes`.
///
/// Register these in [DocumentsModule.registerRoutes] so [RouteRegistry]
/// tracks them. The app layer (`apps/mobile`) uses this constant to build a
/// matching `GoRoute` entry.
abstract final class DocumentsRoutes {
  /// The feature root — entry point shown by [DocumentsPage].
  static const root = RouteDefinition(
    path: '/documents',
    name: 'documents',
  );
}
