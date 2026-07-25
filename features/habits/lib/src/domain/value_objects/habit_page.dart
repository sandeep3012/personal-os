import 'package:feature_habits/src/domain/entities/habit.dart';

/// A single page of [Habit] results from [SearchHabitsUseCase]. Mirrors
/// Finance's `TransactionPage`.
final class HabitPage {
  const HabitPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Habit> items;
  final int totalCount;
  final bool hasNextPage;
}
