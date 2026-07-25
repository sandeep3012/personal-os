import 'package:feature_goals/src/domain/value_objects/goal_target_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoalTargetDate', () {
    test('discards the time-of-day component', () {
      final targetDate = GoalTargetDate(DateTime(2026, 3, 15, 23, 59));
      expect(targetDate.value, DateTime(2026, 3, 15));
    });

    test('two dates on the same calendar day are equal', () {
      final a = GoalTargetDate(DateTime(2026, 3, 15, 1));
      final b = GoalTargetDate(DateTime(2026, 3, 15, 23));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('accepts a far-future date without validation error', () {
      expect(() => GoalTargetDate(DateTime(2099, 1, 1)), returnsNormally);
    });

    test('toString returns YYYY-MM-DD', () {
      expect(GoalTargetDate(DateTime(2026, 3, 5)).toString(), '2026-03-05');
    });
  });
}
