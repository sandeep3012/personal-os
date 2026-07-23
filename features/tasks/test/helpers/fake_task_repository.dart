import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/repositories/i_task_repository.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_page.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:platform_core/platform_core.dart';

/// In-memory [ITaskRepository] for use-case unit tests. Mirrors Finance's
/// `FakeAccountRepository`.
final class FakeTaskRepository implements ITaskRepository {
  final List<Task> _store = [];

  List<Task> get store => List.unmodifiable(_store);

  void seed(List<Task> tasks) {
    _store.clear();
    _store.addAll(tasks);
  }

  @override
  FutureResult<Task?> findById(TaskId id, {required String workspaceId}) async =>
      Result.success(_store.where((t) => t.id == id).firstOrNull);

  @override
  FutureResult<List<Task>> findAll({required String workspaceId}) async =>
      Result.success(List.unmodifiable(_store));

  @override
  FutureResult<List<Task>> findByStatus(
    TaskStatus status, {
    required String workspaceId,
  }) async =>
      Result.success(
        List.unmodifiable(_store.where((t) => t.status == status).toList()),
      );

  @override
  FutureResult<TaskPage> search(TaskQuery query) async {
    var filtered = _store.where((t) => t.workspaceId == query.workspaceId);
    if (query.status != null) {
      filtered = filtered.where((t) => t.status == query.status);
    }
    if (query.titleContains != null && query.titleContains!.isNotEmpty) {
      filtered = filtered.where(
        (t) => t.title.toLowerCase().contains(query.titleContains!.toLowerCase()),
      );
    }
    final all = filtered.toList();
    final start = query.pageIndex * query.pageSize;
    final end = (start + query.pageSize).clamp(0, all.length);
    final items = start >= all.length ? <Task>[] : all.sublist(start, end);

    return Result.success(TaskPage(
      items: items,
      totalCount: all.length,
      hasNextPage: end < all.length,
    ));
  }

  @override
  FutureResult<void> save(Task task) async {
    _store.removeWhere((t) => t.id == task.id);
    _store.add(task);
    return const Result.success(null);
  }

  @override
  FutureResult<void> softDelete(TaskId id, {required String workspaceId}) async {
    _store.removeWhere((t) => t.id == id);
    return const Result.success(null);
  }
}
