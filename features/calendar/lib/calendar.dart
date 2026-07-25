/// Personal OS — Calendar Feature
///
/// Provides scheduled event management: create, update, archive, and
/// delete events — mirrors the Notes/Goals feature vertical.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_calendar/calendar.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete IEventDatabaseExecutor/IEventTransactionRunner binding before
// any Calendar repository is resolved. CalendarModule intentionally does
// not self-register these — mirrors NotesModule/GoalsModule/HabitsModule/
// FinanceModule.
export 'src/data/database/file_backed_event_database_executor.dart';
export 'src/data/database/file_backed_event_transaction_runner.dart';
export 'src/data/database/i_event_database_executor.dart';
export 'src/data/database/i_event_transaction_runner.dart';
export 'src/data/database/in_memory_event_database_executor.dart';
export 'src/data/database/in_memory_event_transaction_runner.dart';

// CalendarModule — needed by RuntimeBootstrap to load the Calendar feature.
export 'src/di/calendar_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Notes exporting `Note`/`NoteStatus`, while use case classes
// remain internal.
export 'src/domain/entities/event.dart';
export 'src/domain/value_objects/event_id.dart';
export 'src/domain/value_objects/event_page.dart';
export 'src/domain/value_objects/event_query.dart';
export 'src/domain/value_objects/event_status.dart';
export 'src/domain/value_objects/event_time_range.dart';

// Complete vertical slice: the Calendar list page.
export 'src/presentation/pages/calendar_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/calendar_routes.dart';
export 'src/presentation/viewmodels/calendar_home_view_model.dart';
export 'src/presentation/viewmodels/calendar_view_model.dart';
