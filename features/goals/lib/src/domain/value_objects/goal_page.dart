import 'package:feature_goals/src/domain/entities/goal.dart';

/// A single page of [Goal] results from [SearchGoalsUseCase]. Mirrors
/// Finance's `TransactionPage`.
final class GoalPage {
  const GoalPage({
    required this.items,
    required this.totalCount,
    required this.hasNextPage,
  });

  final List<Goal> items;
  final int totalCount;
  final bool hasNextPage;
}
