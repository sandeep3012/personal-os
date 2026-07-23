import 'package:platform_core/platform_core.dart';

/// Base exception for all Tasks domain failures.
///
/// Mirrors `FinanceException` — a single named exception type for
/// entity-level structural violations and repository translation failures.
final class TasksException extends AppException {
  const TasksException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
