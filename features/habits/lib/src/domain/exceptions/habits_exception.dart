import 'package:platform_core/platform_core.dart';

/// Base exception for all Habits domain failures.
///
/// Mirrors `FinanceException` — a single named exception type for
/// entity-level structural violations and repository translation failures.
final class HabitsException extends AppException {
  const HabitsException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
