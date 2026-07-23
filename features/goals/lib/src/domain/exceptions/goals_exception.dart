import 'package:platform_core/platform_core.dart';

/// Base exception for all Goals domain failures.
///
/// Mirrors `FinanceException` — a single named exception type for
/// entity-level structural violations and repository translation failures.
final class GoalsException extends AppException {
  const GoalsException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
