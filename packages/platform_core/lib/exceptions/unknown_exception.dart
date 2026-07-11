import 'package:platform_core/exceptions/app_exception.dart';

/// Wraps an unexpected or unclassified error as a typed [AppException].
///
/// Use as a last resort in catch-all blocks to keep the rest of the system
/// working with [Result]-based error propagation even when the original cause
/// is unknown.
///
/// Example:
/// ```dart
/// try {
///   return Result.success(await doWork());
/// } catch (e, st) {
///   return Result.failure(
///     UnknownException(message: 'Unexpected error', cause: e, stackTrace: st),
///   );
/// }
/// ```
final class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unknown error occurred.',
    super.cause,
    super.stackTrace,
  });

  @override
  String toString() => 'UnknownException(message: $message, cause: $cause)';
}
