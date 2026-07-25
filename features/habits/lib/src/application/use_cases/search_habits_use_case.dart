import 'package:application/application.dart';
import 'package:feature_habits/src/domain/repositories/i_habit_repository.dart';
import 'package:feature_habits/src/domain/value_objects/habit_page.dart';
import 'package:feature_habits/src/domain/value_objects/habit_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes a [HabitQuery] and returns a paginated [HabitPage].
///
/// Delegates directly to [IHabitRepository.search], which performs SQL-level
/// filtering and pagination via [HabitDao.query] (DOC-032 §7.1) — orchestration
/// only, no in-memory filtering here.
final class SearchHabitsUseCase
    implements AsyncUseCase<HabitQuery, HabitPage> {
  const SearchHabitsUseCase({required IHabitRepository habitRepository})
      : _habitRepository = habitRepository;

  final IHabitRepository _habitRepository;

  @override
  Future<Result<HabitPage>> execute(HabitQuery input) => _habitRepository.search(input);
}
