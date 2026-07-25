/// Personal OS — Goals Feature
///
/// Provides personal goal management: create, update, record progress,
/// archive, and delete goals — mirrors the Habits feature vertical.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_goals/goals.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete IGoalDatabaseExecutor/IGoalTransactionRunner binding before any
// Goals repository is resolved. GoalsModule intentionally does not
// self-register these — mirrors HabitsModule/FinanceModule.
export 'src/data/database/file_backed_goal_database_executor.dart';
export 'src/data/database/file_backed_goal_transaction_runner.dart';
export 'src/data/database/i_goal_database_executor.dart';
export 'src/data/database/i_goal_transaction_runner.dart';
export 'src/data/database/in_memory_goal_database_executor.dart';
export 'src/data/database/in_memory_goal_transaction_runner.dart';

// GoalsModule — needed by RuntimeBootstrap to load the Goals feature.
export 'src/di/goals_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Habits exporting `Habit`/`HabitStatus`, while use case classes
// remain internal (DOC-031 §7).
export 'src/domain/entities/goal.dart';
export 'src/domain/value_objects/goal_id.dart';
export 'src/domain/value_objects/goal_page.dart';
export 'src/domain/value_objects/goal_query.dart';
export 'src/domain/value_objects/goal_status.dart';
export 'src/domain/value_objects/goal_target_date.dart';

// Complete vertical slice: the Goals list page.
export 'src/presentation/pages/goals_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/goals_routes.dart';
export 'src/presentation/viewmodels/goals_home_view_model.dart';
export 'src/presentation/viewmodels/goals_view_model.dart';
