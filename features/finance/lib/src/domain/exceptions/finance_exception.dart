import 'package:platform_core/platform_core.dart';

/// Base exception for all Finance domain failures.
///
/// Named subtypes are defined for failures that callers must handle
/// distinctly (e.g. [AccountNotFoundException]). Throw [FinanceException]
/// directly only for entity-level structural violations where no named
/// subtype applies.
final class FinanceException extends AppException {
  const FinanceException({
    required super.message,
    super.cause,
    super.stackTrace,
  });
}
