/// Personal OS — Tasks Feature
///
/// Provides personal task management: create, update, complete, archive,
/// and delete tasks (DOC-032).
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_tasks/tasks.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete ITaskDatabaseExecutor/ITaskTransactionRunner binding before any
// Tasks repository is resolved. TasksModule intentionally does not
// self-register these — mirrors FinanceModule.
export 'src/data/database/file_backed_task_database_executor.dart';
export 'src/data/database/file_backed_task_transaction_runner.dart';
export 'src/data/database/i_task_database_executor.dart';
export 'src/data/database/i_task_transaction_runner.dart';
export 'src/data/database/in_memory_task_database_executor.dart';
export 'src/data/database/in_memory_task_transaction_runner.dart';

// TasksModule — needed by RuntimeBootstrap to load the Tasks feature.
export 'src/di/tasks_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Finance exporting `Account`/`Transaction`/`AccountType`/
// `TransactionType`, while use case classes remain internal (DOC-031 §7: "no
// consumer imports a use case type directly" — resolved via DI instead).
export 'src/domain/entities/task.dart';
export 'src/domain/value_objects/task_due_date.dart';
export 'src/domain/value_objects/task_id.dart';
export 'src/domain/value_objects/task_page.dart';
export 'src/domain/value_objects/task_query.dart';
export 'src/domain/value_objects/task_status.dart';

// Complete vertical slice: the Tasks list page.
export 'src/presentation/pages/tasks_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/tasks_routes.dart';
export 'src/presentation/viewmodels/tasks_home_view_model.dart';
export 'src/presentation/viewmodels/tasks_view_model.dart';
