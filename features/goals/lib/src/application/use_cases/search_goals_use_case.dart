import 'package:application/application.dart';
import 'package:feature_goals/src/domain/repositories/i_goal_repository.dart';
import 'package:feature_goals/src/domain/value_objects/goal_page.dart';
import 'package:feature_goals/src/domain/value_objects/goal_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes a [GoalQuery] and returns a paginated [GoalPage].
///
/// Delegates directly to [IGoalRepository.search], which performs SQL-level
/// filtering and pagination via [GoalDao.query] (DOC-032 §7.1) — orchestration
/// only, no in-memory filtering here.
final class SearchGoalsUseCase
    implements AsyncUseCase<GoalQuery, GoalPage> {
  const SearchGoalsUseCase({required IGoalRepository goalRepository})
      : _goalRepository = goalRepository;

  final IGoalRepository _goalRepository;

  @override
  Future<Result<GoalPage>> execute(GoalQuery input) => _goalRepository.search(input);
}
