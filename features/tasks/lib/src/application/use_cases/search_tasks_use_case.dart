import 'package:application/application.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_page.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:platform_core/platform_core.dart';

/// Executes a [TaskQuery] and returns a paginated [TaskPage].
///
/// Delegates directly to [ITaskRepository.search], which performs SQL-level
/// filtering and pagination via [TaskDao.query] (DOC-032 §7.1) — orchestration
/// only, no in-memory filtering here.
final class SearchTasksUseCase
    implements AsyncUseCase<TaskQuery, TaskPage> {
  const SearchTasksUseCase({required ITaskRepository taskRepository})
      : _taskRepository = taskRepository;

  final ITaskRepository _taskRepository;

  @override
  Future<Result<TaskPage>> execute(TaskQuery input) => _taskRepository.search(input);
}
