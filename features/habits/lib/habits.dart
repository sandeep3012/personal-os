/// Personal OS — Habits Feature
///
/// Provides personal habit management: create, update, complete, archive,
/// and delete habits (DOC-032).
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_habits/habits.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete IHabitDatabaseExecutor/IHabitTransactionRunner binding before any
// Habits repository is resolved. HabitsModule intentionally does not
// self-register these — mirrors FinanceModule.
export 'src/data/database/file_backed_habit_database_executor.dart';
export 'src/data/database/file_backed_habit_transaction_runner.dart';
export 'src/data/database/i_habit_database_executor.dart';
export 'src/data/database/i_habit_transaction_runner.dart';
export 'src/data/database/in_memory_habit_database_executor.dart';
export 'src/data/database/in_memory_habit_transaction_runner.dart';

// HabitsModule — needed by RuntimeBootstrap to load the Habits feature.
export 'src/di/habits_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Finance exporting `Account`/`Transaction`/`AccountType`/
// `TransactionType`, while use case classes remain internal (DOC-031 §7: "no
// consumer imports a use case type directly" — resolved via DI instead).
export 'src/domain/entities/habit.dart';
export 'src/domain/value_objects/habit_frequency.dart';
export 'src/domain/value_objects/habit_id.dart';
export 'src/domain/value_objects/habit_page.dart';
export 'src/domain/value_objects/habit_query.dart';
export 'src/domain/value_objects/habit_status.dart';

// Complete vertical slice: the Habits list page.
export 'src/presentation/pages/habits_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/habits_routes.dart';
export 'src/presentation/viewmodels/habits_home_view_model.dart';
export 'src/presentation/viewmodels/habits_view_model.dart';
