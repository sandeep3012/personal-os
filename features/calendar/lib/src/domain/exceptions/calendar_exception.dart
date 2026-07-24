import 'package:platform_core/platform_core.dart';

/// Base exception for all Calendar domain failures.
///
/// Mirrors `NotesException`/`GoalsException` — a single named exception
/// type for entity-level structural violations and repository translation
/// failures.
final class CalendarException extends AppException {
  const CalendarException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
