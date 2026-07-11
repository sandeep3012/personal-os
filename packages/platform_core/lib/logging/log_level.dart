/// Severity levels for log messages, ordered from least to most severe.
enum LogLevel {
  /// Fine-grained diagnostic detail — only useful during debugging.
  trace,

  /// Diagnostic information useful during development.
  debug,

  /// Informational messages that highlight normal application progress.
  info,

  /// Potentially harmful situations that do not prevent operation.
  warning,

  /// Errors that allow the application to continue running.
  error,

  /// Severe errors that likely cause the application to abort.
  fatal,
}
