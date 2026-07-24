import 'package:platform_core/platform_core.dart';

/// Base exception for all Notes domain failures.
///
/// Mirrors `GoalsException`/`FinanceException` — a single named exception
/// type for entity-level structural violations and repository translation
/// failures.
final class NotesException extends AppException {
  const NotesException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
