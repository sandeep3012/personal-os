import 'package:platform_core/platform_core.dart';

/// Base exception for all Documents domain failures.
///
/// Mirrors `NotesException`/`GoalsException` — a single named exception
/// type for entity-level structural violations and repository translation
/// failures.
final class DocumentsException extends AppException {
  const DocumentsException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
