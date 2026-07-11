import 'package:platform_core/logging/log_level.dart';

/// Contract for all loggers in Personal OS.
///
/// Consumers should depend on this interface — never on a concrete logger —
/// so that the underlying sink (console, file, remote) can be swapped via DI.
///
/// Example:
/// ```dart
/// class MyService {
///   const MyService(this._logger);
///   final ILogger _logger;
///
///   void doWork() {
///     _logger.info('Starting work');
///   }
/// }
/// ```
abstract interface class ILogger {
  /// Logs a [message] at the given [level].
  ///
  /// [error] and [stackTrace] are optional; include them for exception
  /// scenarios.
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  });

  /// Logs a trace-level [message].
  void trace(String message, {Object? error, StackTrace? stackTrace});

  /// Logs a debug-level [message].
  void debug(String message, {Object? error, StackTrace? stackTrace});

  /// Logs an info-level [message].
  void info(String message, {Object? error, StackTrace? stackTrace});

  /// Logs a warning-level [message].
  void warning(String message, {Object? error, StackTrace? stackTrace});

  /// Logs an error-level [message].
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// Logs a fatal-level [message].
  void fatal(String message, {Object? error, StackTrace? stackTrace});
}
