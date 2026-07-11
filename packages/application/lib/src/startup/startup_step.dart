import 'package:application/src/startup/startup_context.dart';

/// A single named step in a [StartupPipeline].
///
/// Implement this interface to add initialisation work to the startup sequence.
/// Steps are executed in the order they were added to the pipeline, and each
/// step receives a [StartupContext] giving it access to configuration and the
/// service registry.
///
/// Example:
/// ```dart
/// final class StorageInitStep implements StartupStep {
///   @override
///   String get name => 'storage-init';
///
///   @override
///   Future<void> execute(StartupContext context) async {
///     final db = context.locator.get<IDatabase>();
///     await db.open();
///   }
/// }
/// ```
abstract interface class StartupStep {
  /// Human-readable name used for logging and diagnostics.
  String get name;

  /// Executes the initialisation work for this step.
  ///
  /// Throws on unrecoverable failure; the pipeline propagates the exception to
  /// the caller.
  Future<void> execute(StartupContext context);
}
