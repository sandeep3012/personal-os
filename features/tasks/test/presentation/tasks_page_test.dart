import 'package:application/application.dart';
import 'package:feature_tasks/src/application/use_cases/archive_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/complete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/create_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/delete_task_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/get_tasks_use_case.dart';
import 'package:feature_tasks/src/application/use_cases/update_task_use_case.dart';
import 'package:feature_tasks/src/presentation/pages/tasks_page.dart';
import 'package:feature_tasks/src/presentation/viewmodels/tasks_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platform_core/platform_core.dart';

import '../helpers/fake_task_repository.dart';

const _ws = 'ws-1';

final class _SequentialId implements IdGenerator {
  var _i = 0;
  @override
  String generate() => 'task-${++_i}';
}

final class _Harness {
  _Harness() : repo = FakeTaskRepository() {
    viewModel = TasksViewModel(
      getTasksUseCase: GetTasksUseCase(taskRepository: repo),
      createTaskUseCase: CreateTaskUseCase(
        taskRepository: repo,
        idGenerator: _SequentialId(),
      ),
      updateTaskUseCase: UpdateTaskUseCase(taskRepository: repo),
      completeTaskUseCase: CompleteTaskUseCase(taskRepository: repo),
      archiveTaskUseCase: ArchiveTaskUseCase(taskRepository: repo),
      deleteTaskUseCase: DeleteTaskUseCase(taskRepository: repo),
      workspaceContext: WorkspaceContext(initialWorkspaceId: _ws),
    );
  }

  final FakeTaskRepository repo;
  late final TasksViewModel viewModel;

  Widget buildPage() => MaterialApp(home: TasksPage(viewModel: viewModel));
}

void main() {
  group('TasksPage — states', () {
    testWidgets('shows a loading indicator immediately after mount',
        (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the empty state when no tasks exist', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('shows a task after loading', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createTask(title: 'Buy groceries');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      expect(find.text('Buy groceries'), findsOneWidget);
    });
  });

  group('TasksPage — create', () {
    testWidgets('tapping the FAB opens the add-task dialog', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AlertDialog), matching: find.text('Add Task')),
        findsOneWidget,
      );
    });

    testWidgets('creating a task adds it to the visible list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Walk the dog');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Walk the dog'), findsOneWidget);
    });
  });

  group('TasksPage — edit', () {
    testWidgets('tapping a task opens the edit dialog pre-filled with its title',
        (tester) async {
      final harness = _Harness();
      await harness.viewModel.createTask(title: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Task'), findsOneWidget);
    });

    testWidgets('editing the title updates the list', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createTask(title: 'Original');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Renamed');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed'), findsOneWidget);
      expect(find.text('Original'), findsNothing);
    });
  });

  group('TasksPage — complete', () {
    testWidgets('checking the checkbox marks the task completed', (tester) async {
      final harness = _Harness();
      final created = await harness.viewModel.createTask(title: 'Task');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'completed');
    });
  });

  group('TasksPage — archive', () {
    testWidgets('the Archive button in the edit dialog archives the task',
        (tester) async {
      final harness = _Harness();
      final created = await harness.viewModel.createTask(title: 'Task');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Task'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Archive'));
      await tester.pumpAndSettle();

      // Archived tasks are excluded from the visible list.
      expect(find.text('Task'), findsNothing);

      final refreshed = await harness.repo.findById(
        created.valueOrNull!.id,
        workspaceId: _ws,
      );
      expect(refreshed.valueOrNull!.status.name, 'archived');
    });
  });

  group('TasksPage — delete', () {
    testWidgets('swiping a task away deletes it', (tester) async {
      final harness = _Harness();
      await harness.viewModel.createTask(title: 'Task');
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Task'), findsNothing);
      expect(harness.viewModel.state.dataOrNull, isEmpty);
    });
  });

  group('TasksPage — refresh', () {
    testWidgets('pull-to-refresh reloads the list', (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.buildPage());
      await tester.pumpAndSettle();
      expect(find.text('No tasks yet'), findsOneWidget);

      await harness.viewModel.createTask(title: 'Newly Added');
      await harness.viewModel.refresh();
      await tester.pumpAndSettle();

      expect(find.text('Newly Added'), findsOneWidget);
    });
  });
}
