import 'package:feature_habits/src/domain/value_objects/habit_frequency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitFrequency.maxGapInDays', () {
    test('daily allows a gap of at most 1 day', () {
      expect(HabitFrequency.daily.maxGapInDays, 1);
    });

    test('weekly allows a gap of at most 7 days', () {
      expect(HabitFrequency.weekly.maxGapInDays, 7);
    });
  });
}
