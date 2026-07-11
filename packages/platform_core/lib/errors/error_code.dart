/// Machine-readable error codes for structured error handling and telemetry.
///
/// Each [AppException] subtype maps to a [ErrorCode]. This allows consumers
/// to branch on error kind without `is` type checks.
///
/// Codes are additive — add new values as new exception types are introduced.
/// Never remove or reorder existing values (breaks serialised error reports).
enum ErrorCode {
  /// An unknown or unclassified error.
  unknown,

  /// An input field or parameter failed a validation rule.
  validation,

  /// The application could not be configured correctly.
  configuration,

  /// The requested resource was not found.
  notFound,

  /// The caller does not have permission for the requested operation.
  unauthorised,
}
