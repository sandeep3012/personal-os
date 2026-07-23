import 'package:feature_tasks/src/domain/value_objects/task_due_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskDueDate', () {
    test('discards the time-of-day component', () {
      final dueDate = TaskDueDate(DateTime(2026, 3, 15, 23, 59));
      expect(dueDate.value, DateTime(2026, 3, 15));
    });

    test('two dates on the same calendar day are equal', () {
      final a = TaskDueDate(DateTime(2026, 3, 15, 1));
      final b = TaskDueDate(DateTime(2026, 3, 15, 23));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('accepts a far-future date without validation error', () {
      // Unlike Finance's TransactionDate, no range restriction applies
      // (DOC-032 §5.3/§6.2) — this must not throw.
      expect(
        () => TaskDueDate(DateTime(2099, 1, 1)),
        returnsNormally,
      );
    });

    test('toString returns YYYY-MM-DD', () {
      expect(TaskDueDate(DateTime(2026, 3, 5)).toString(), '2026-03-05');
    });
  });
}
