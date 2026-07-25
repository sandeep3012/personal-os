/// Personal OS — Assets Feature
///
/// Provides asset management: create, update, dispose, archive, and
/// delete assets — mirrors the Notes/Goals feature vertical.
///
/// ## Public API consumed by apps/mobile
///
/// ```dart
/// import 'package:feature_assets/assets.dart';
/// ```
library;

// Persistence leaf interfaces + the default in-memory/file-backed
// implementations. The app layer (composition root) must register a
// concrete IAssetDatabaseExecutor/IAssetTransactionRunner binding before
// any Assets repository is resolved. AssetsModule intentionally does
// not self-register these — mirrors NotesModule/GoalsModule/HabitsModule/
// FinanceModule.
export 'src/data/database/file_backed_asset_database_executor.dart';
export 'src/data/database/file_backed_asset_transaction_runner.dart';
export 'src/data/database/i_asset_database_executor.dart';
export 'src/data/database/i_asset_transaction_runner.dart';
export 'src/data/database/in_memory_asset_database_executor.dart';
export 'src/data/database/in_memory_asset_transaction_runner.dart';

// AssetsModule — needed by RuntimeBootstrap to load the Assets feature.
export 'src/di/assets_module.dart';

// Domain entity/value-object types the app layer needs for UI state —
// mirrors Notes exporting `Note`/`NoteStatus`, while use case classes
// remain internal.
export 'src/domain/entities/asset.dart';
export 'src/domain/value_objects/asset_id.dart';
export 'src/domain/value_objects/asset_page.dart';
export 'src/domain/value_objects/asset_query.dart';
export 'src/domain/value_objects/asset_status.dart';

// Complete vertical slice: the Assets list page.
export 'src/presentation/pages/assets_page.dart';

// Route constants — needed by the app layer to build go_router entries.
export 'src/presentation/routes/assets_routes.dart';
export 'src/presentation/viewmodels/assets_home_view_model.dart';
export 'src/presentation/viewmodels/assets_view_model.dart';
