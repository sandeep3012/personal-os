/// Base class for all application-level exceptions in Personal OS.
///
/// Prefer concrete subtypes ([ValidationException], [ConfigurationException],
/// [UnknownException]) over catching this directly. Catching [AppException]
/// is acceptable at boundary layers (e.g. repository → use-case) when the
/// specific type is irrelevant.
abstract class AppException implements Exception {
  const AppException({
    required this.message,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying error or exception that triggered this exception, if any.
  final Object? cause;

  /// Optional stack trace captured at the throw site.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      other is AppException &&
      runtimeType == other.runtimeType &&
      message == other.message &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, cause);

  @override
  String toString() {
    final buffer = StringBuffer('$runtimeType(message: $message');
    if (cause != null) buffer.write(', cause: $cause');
    buffer.write(')');
    return buffer.toString();
  }
}
