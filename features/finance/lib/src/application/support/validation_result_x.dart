import 'package:application/application.dart';
import 'package:feature_finance/src/domain/exceptions/finance_exception.dart';

/// Converts an invalid [ValidationResult] into a [FinanceException] so use
/// cases can return it via `Result.failure` without re-deriving the message.
extension ValidationResultToException on ValidationResult {
  /// Joins all failure messages into a single [FinanceException].
  ///
  /// Callers must check [ValidationResult.isInvalid] before calling this.
  FinanceException toFinanceException() {
    return FinanceException(
      message: failures.map((f) => f.message).join(' '),
    );
  }
}
