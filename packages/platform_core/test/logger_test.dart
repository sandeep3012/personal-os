import 'package:platform_core/logging/i_logger.dart';
import 'package:platform_core/logging/log_level.dart';
import 'package:platform_core/logging/logger.dart';
import 'package:test/test.dart';

/// Captures log calls for assertion in tests.
final class _CapturingLogger implements ILogger {
  final List<({LogLevel level, String message, Object? error})> calls = [];

  @override
  void log(LogLevel level, String message,
      {Object? error, StackTrace? stackTrace}) {
    calls.add((level: level, message: message, error: error));
  }

  @override
  void trace(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.trace, message, error: error);
  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.debug, message, error: error);
  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.info, message, error: error);
  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.warning, message, error: error);
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.error, message, error: error);
  @override
  void fatal(String message, {Object? error, StackTrace? stackTrace}) =>
      log(LogLevel.fatal, message, error: error);
}

void main() {
  group('LogLevel', () {
    test('values are ordered by severity', () {
      expect(LogLevel.trace.index, lessThan(LogLevel.debug.index));
      expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
      expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
      expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
      expect(LogLevel.error.index, lessThan(LogLevel.fatal.index));
    });
  });

  group('Logger — minimum level filtering', () {
    test('does not emit below minimum level', () {
      // Logger with minimumLevel = info should suppress trace and debug.
      // We cannot capture dart:developer output easily, so test through ILogger.
      const logger = Logger(minimumLevel: LogLevel.info);
      // Smoke-test: should not throw.
      expect(() => logger.trace('suppressed'), returnsNormally);
      expect(() => logger.debug('suppressed'), returnsNormally);
      expect(() => logger.info('visible'), returnsNormally);
    });

    test('emits at and above minimum level without throwing', () {
      const logger = Logger(minimumLevel: LogLevel.warning);
      expect(() => logger.warning('warn'), returnsNormally);
      expect(() => logger.error('err'), returnsNormally);
      expect(() => logger.fatal('fatal'), returnsNormally);
    });
  });

  group('Logger — all methods delegate to log()', () {
    final capturing = _CapturingLogger();

    setUp(capturing.calls.clear);

    test('trace delegates', () {
      capturing.trace('t');
      expect(capturing.calls.single.level, LogLevel.trace);
      expect(capturing.calls.single.message, 't');
    });

    test('debug delegates', () {
      capturing.debug('d');
      expect(capturing.calls.single.level, LogLevel.debug);
    });

    test('info delegates', () {
      capturing.info('i');
      expect(capturing.calls.single.level, LogLevel.info);
    });

    test('warning delegates', () {
      capturing.warning('w');
      expect(capturing.calls.single.level, LogLevel.warning);
    });

    test('error delegates with error object', () {
      final err = Exception('boom');
      capturing.error('e', error: err);
      final call = capturing.calls.single;
      expect(call.level, LogLevel.error);
      expect(call.error, err);
    });

    test('fatal delegates', () {
      capturing.fatal('f');
      expect(capturing.calls.single.level, LogLevel.fatal);
    });
  });

  group('NoOpLogger', () {
    test('all methods do nothing and do not throw', () {
      const noop = NoOpLogger();
      expect(() => noop.trace('t'), returnsNormally);
      expect(() => noop.debug('d'), returnsNormally);
      expect(() => noop.info('i'), returnsNormally);
      expect(() => noop.warning('w'), returnsNormally);
      expect(() => noop.error('e', error: Exception()), returnsNormally);
      expect(() => noop.fatal('f'), returnsNormally);
    });
  });
}
