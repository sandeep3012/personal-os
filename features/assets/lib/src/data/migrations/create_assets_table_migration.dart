import 'package:feature_assets/src/data/schema/assets_schema.dart';
import 'package:platform_storage/migrations/migration.dart';
import 'package:platform_storage/migrations/migration_context.dart';

/// Creates the `assets` table and its supporting indexes.
///
/// [Asset.status] is a `TEXT` column constrained to the values of the
/// actual `AssetStatus` enum (`active`, `disposed`, `archived` — see
/// `asset_status.dart`). Mirrors Notes' `CreateNotesTableMigration`
/// exactly, including its current status: declared for parity and as
/// schema-as-code documentation, not yet wired into a runtime migration
/// runner, since the active executor is the hand-rolled in-memory/
/// file-backed engine rather than a real SQL engine (same as
/// Notes/Goals/Habits/Finance/Tasks today).
///
/// Soft delete is represented by nullable [AssetsSchema.assetDeletedAt]
/// rather than a boolean flag, so the deletion moment is recoverable for
/// audit/debugging — the [Asset] entity itself has no such field; this is
/// purely a storage-layer concern.
final class CreateAssetsTableMigration extends Migration {
  const CreateAssetsTableMigration() : super(version: 1);

  @override
  Future<void> up(MigrationContext ctx) async {
    await ctx.execute('''
      CREATE TABLE ${AssetsSchema.assetsTable} (
        ${AssetsSchema.assetId}          TEXT    PRIMARY KEY,
        ${AssetsSchema.assetWorkspaceId} TEXT    NOT NULL,
        ${AssetsSchema.assetName}        TEXT    NOT NULL CHECK (length(trim(${AssetsSchema.assetName})) > 0),
        ${AssetsSchema.assetCategory}    TEXT    NOT NULL CHECK (length(trim(${AssetsSchema.assetCategory})) > 0),
        ${AssetsSchema.assetValue}       REAL    NOT NULL CHECK (${AssetsSchema.assetValue} >= 0),
        ${AssetsSchema.assetAcquisitionDate} TEXT NOT NULL,
        ${AssetsSchema.assetNotes}       TEXT,
        ${AssetsSchema.assetStatus}      TEXT    NOT NULL CHECK (${AssetsSchema.assetStatus} IN ('active', 'disposed', 'archived')),
        ${AssetsSchema.assetCreatedAt}   TEXT    NOT NULL,
        ${AssetsSchema.assetUpdatedAt}   TEXT    NOT NULL,
        ${AssetsSchema.assetDeletedAt}   TEXT
      )
    ''');

    // Serves IAssetRepository.findAll(workspaceId) and general workspace
    // scoping.
    await ctx.execute('''
      CREATE INDEX idx_assets_workspace_id
      ON ${AssetsSchema.assetsTable} (${AssetsSchema.assetWorkspaceId})
    ''');

    // Serves IAssetRepository.findByStatus(workspaceId, status); excludes
    // soft-deleted rows.
    await ctx.execute('''
      CREATE INDEX idx_assets_workspace_status
      ON ${AssetsSchema.assetsTable} (${AssetsSchema.assetWorkspaceId}, ${AssetsSchema.assetStatus})
      WHERE ${AssetsSchema.assetDeletedAt} IS NULL
    ''');
  }

  @override
  Future<void> down(MigrationContext ctx) async {
    await ctx.execute('DROP INDEX IF EXISTS idx_assets_workspace_status');
    await ctx.execute('DROP INDEX IF EXISTS idx_assets_workspace_id');
    await ctx.execute('DROP TABLE IF EXISTS ${AssetsSchema.assetsTable}');
  }
}
