import 'package:platform_core/platform_core.dart';

/// Base exception for all Assets domain failures.
///
/// Mirrors `NotesException`/`GoalsException` — a single named exception
/// type for entity-level structural violations and repository translation
/// failures.
final class AssetsException extends AppException {
  const AssetsException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
