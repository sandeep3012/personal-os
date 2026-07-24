/// Personal OS — Documents Feature
///
/// Provides document management: create, update, archive, and
/// delete documents — mirrors the Notes/Goals feature vertical.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_documents/documents.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete IDocumentDatabaseExecutor/IDocumentTransactionRunner binding before
// any Documents repository is resolved. DocumentsModule intentionally does
// not self-register these — mirrors NotesModule/GoalsModule/HabitsModule/
// FinanceModule.
export 'src/data/database/file_backed_document_database_executor.dart';
export 'src/data/database/file_backed_document_transaction_runner.dart';
export 'src/data/database/i_document_database_executor.dart';
export 'src/data/database/i_document_transaction_runner.dart';
export 'src/data/database/in_memory_document_database_executor.dart';
export 'src/data/database/in_memory_document_transaction_runner.dart';

// DocumentsModule — needed by RuntimeBootstrap to load the Documents feature.
export 'src/di/documents_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Notes exporting `Note`/`NoteStatus`, while use case classes
// remain internal.
export 'src/domain/entities/document.dart';
export 'src/domain/value_objects/document_id.dart';
export 'src/domain/value_objects/document_page.dart';
export 'src/domain/value_objects/document_query.dart';
export 'src/domain/value_objects/document_status.dart';

// Complete vertical slice: the Documents list page.
export 'src/presentation/pages/documents_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/documents_routes.dart';
export 'src/presentation/viewmodels/documents_home_view_model.dart';
export 'src/presentation/viewmodels/documents_view_model.dart';
