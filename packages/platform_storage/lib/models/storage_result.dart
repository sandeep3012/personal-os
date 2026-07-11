import 'package:platform_storage/exceptions/storage_exception.dart';

/// The outcome of a storage operation: either [StorageOutcome.success] or
/// [StorageOutcome.failure].
enum StorageOutcome { success, failure }

/// An immutable value object describing the result of a storage operation.
///
/// Unlike [Result<T>], [StorageResult] carries additional metadata useful for
/// logging and diagnostics: the operation name, duration, and optional row
/// count.
///
/// Use [StorageResult.success] / [StorageResult.failure] factories.
final class StorageResult {
  const StorageResult._({
    required this.outcome,
    required this.operationName,
    this.affectedCount,
    this.duration,
    this.exception,
  });

  /// Creates a successful storage result.
  const factory StorageResult.success({
    required String operationName,
    int? affectedCount,
    Duration? duration,
  }) = _SuccessResult;

  /// Creates a failed storage result.
  const factory StorageResult.failure({
    required String operationName,
    required StorageException exception,
    Duration? duration,
  }) = _FailureResult;

  /// Whether the operation succeeded or failed.
  final StorageOutcome outcome;

  /// A human-readable name for the operation (e.g. `'insert user'`).
  final String operationName;

  /// Number of rows or records affected, if applicable.
  final int? affectedCount;

  /// Time taken by the operation.
  final Duration? duration;

  /// The exception that caused the failure, if [outcome] is
  /// [StorageOutcome.failure].
  final StorageException? exception;

  bool get isSuccess => outcome == StorageOutcome.success;
  bool get isFailure => outcome == StorageOutcome.failure;

  @override
  String toString() {
    final buffer = StringBuffer('StorageResult(');
    buffer.write('outcome: $outcome, operation: $operationName');
    if (affectedCount != null) buffer.write(', affectedCount: $affectedCount');
    if (duration != null) buffer.write(', duration: $duration');
    if (exception != null) buffer.write(', exception: $exception');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      other is StorageResult &&
      outcome == other.outcome &&
      operationName == other.operationName &&
      affectedCount == other.affectedCount &&
      exception == other.exception;

  @override
  int get hashCode =>
      Object.hash(outcome, operationName, affectedCount, exception);
}

final class _SuccessResult extends StorageResult {
  const _SuccessResult({
    required super.operationName,
    super.affectedCount,
    super.duration,
  }) : super._(outcome: StorageOutcome.success);
}

final class _FailureResult extends StorageResult {
  const _FailureResult({
    required super.operationName,
    required StorageException exception,
    super.duration,
  }) : super._(outcome: StorageOutcome.failure, exception: exception);
}
