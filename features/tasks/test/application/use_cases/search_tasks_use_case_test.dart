import 'package:feature_tasks/src/application/use_cases/search_tasks_use_case.dart';
import 'package:feature_tasks/src/domain/entities/task.dart';
import 'package:feature_tasks/src/domain/value_objects/task_id.dart';
import 'package:feature_tasks/src/domain/value_objects/task_query.dart';
import 'package:feature_tasks/src/domain/value_objects/task_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

Task _task(String id, String title, TaskStatus status) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: TaskId(id),
    workspaceId: _ws,
    title: title,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeTaskRepository repo;
  late SearchTasksUseCase useCase;

  setUp(() {
    repo = FakeTaskRepository()
      ..seed([
        _task('t1', 'Buy groceries', TaskStatus.todo),
        _task('t2', 'Pay rent', TaskStatus.completed),
        _task('t3', 'Buy a gift', TaskStatus.todo),
      ]);
    useCase = SearchTasksUseCase(taskRepository: repo);
  });

  group('SearchTasksUseCase', () {
    test('filters by status', () async {
      final result = await useCase.execute(
        const TaskQuery(workspaceId: _ws, status: TaskStatus.todo),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 2);
    });

    test('filters by title (case-insensitive contains)', () async {
      final result = await useCase.execute(
        const TaskQuery(workspaceId: _ws, titleContains: 'buy'),
      );

      expect(result.valueOrNull!.items, hasLength(2));
    });

    test('paginates results', () async {
      final result = await useCase.execute(
        const TaskQuery(workspaceId: _ws, pageSize: 2, pageIndex: 0),
      );

      expect(result.valueOrNull!.items, hasLength(2));
      expect(result.valueOrNull!.totalCount, 3);
      expect(result.valueOrNull!.hasNextPage, isTrue);
    });
  });
}
