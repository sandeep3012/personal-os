/// Personal OS — Notes Feature
///
/// Provides free-form note taking: create, update, tag, archive, and
/// delete notes — mirrors the Goals feature vertical.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_notes/notes.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete INoteDatabaseExecutor/INoteTransactionRunner binding before any
// Notes repository is resolved. NotesModule intentionally does not
// self-register these — mirrors GoalsModule/HabitsModule/FinanceModule.
export 'src/data/database/file_backed_note_database_executor.dart';
export 'src/data/database/file_backed_note_transaction_runner.dart';
export 'src/data/database/i_note_database_executor.dart';
export 'src/data/database/i_note_transaction_runner.dart';
export 'src/data/database/in_memory_note_database_executor.dart';
export 'src/data/database/in_memory_note_transaction_runner.dart';

// NotesModule — needed by RuntimeBootstrap to load the Notes feature.
export 'src/di/notes_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Goals exporting `Goal`/`GoalStatus`, while use case classes remain
// internal.
export 'src/domain/entities/note.dart';
export 'src/domain/value_objects/note_id.dart';
export 'src/domain/value_objects/note_page.dart';
export 'src/domain/value_objects/note_query.dart';
export 'src/domain/value_objects/note_status.dart';

// Complete vertical slice: the Notes list page.
export 'src/presentation/pages/notes_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/notes_routes.dart';
export 'src/presentation/viewmodels/notes_home_view_model.dart';
export 'src/presentation/viewmodels/notes_view_model.dart';
