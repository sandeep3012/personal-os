import 'dart:developer' as dev;

import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_core/logging/log_level.dart';

// Maps LogLevel to dart:developer log levels (0-1200 range).
const _devLevels = {
  LogLevel.trace: 200,
  LogLevel.debug: 400,
  LogLevel.info: 800,
  LogLevel.warning: 900,
  LogLevel.error: 1000,
  LogLevel.fatal: 1200,
};

/// Default platform-independent logger backed by [dart:developer].
///
/// Output is visible in Dart DevTools and IDE debug consoles without
/// requiring any native platform channel. Suitable for all targets:
/// Android, iOS, web, desktop.
///
/// Supply a [tag] to identify the component emitting the log. Messages
/// below [minimumLevel] are silently discarded.
///
/// Example:
/// ```dart
/// final log = Logger(tag: 'AuthService');
/// log.info('User signed in');
/// log.warning('Token expiring soon');
/// log.error('Sign-in failed', error: e, stackTrace: st);
/// ```
final class Logger implements ILogger {
  const Logger({
    this.tag = '',
    this.minimumLevel = LogLevel.debug,
  });

  /// Label prepended to every log line (e.g. the class name).
  final String tag;

  /// Messages below this level are silently dropped.
  final LogLevel minimumLevel;

  @override
  void log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minimumLevel.index) return;
    final levelLabel = '[${level.name.toUpperCase()}]';
    final body = tag.isEmpty ? message : '[$tag] $message';
    dev.log(
      '$levelLabel $body',
      name: tag.isEmpty ? 'App' : tag,
      level: _devLevels[level] ?? 0,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  void trace(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.trace, message, error: error, stackTrace: stackTrace);

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.debug, message, error: error, stackTrace: stackTrace);

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.info, message, error: error, stackTrace: stackTrace);

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warning, message, error: error, stackTrace: stackTrace);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error, stackTrace: stackTrace);

  @override
  void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.fatal, message, error: error, stackTrace: stackTrace);
}

/// A no-op logger that discards all messages.
///
/// Useful as a default/null object in tests or when logging is intentionally
/// disabled.
final class NoOpLogger implements ILogger {
  const NoOpLogger();

  @override
  void log(LogLevel level, String message,
      {Object? error, StackTrace? stackTrace}) {}

  @override
  void trace(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}

  @override
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {}
}
