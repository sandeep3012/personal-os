/// Table and column name constants for the Assets SQLite schema.
///
/// Single source of truth for identifiers referenced by both the schema
/// migration and the repository/DAO layer — mirrors Notes' `NotesSchema`.
abstract final class AssetsSchema {
  static const assetsTable = 'assets';

  static const assetId = 'asset_id';
  static const assetWorkspaceId = 'workspace_id';
  static const assetName = 'name';
  static const assetCategory = 'category';
  static const assetValue = 'value';
  static const assetAcquisitionDate = 'acquisition_date';
  static const assetNotes = 'notes';
  static const assetStatus = 'status';
  static const assetCreatedAt = 'created_at';
  static const assetUpdatedAt = 'updated_at';
  static const assetDeletedAt = 'deleted_at';

  // ── Column ordering (DAO insert/update column lists) ─────────────────────

  static const List<String> assetColumns = [
    assetId,
    assetWorkspaceId,
    assetName,
    assetCategory,
    assetValue,
    assetAcquisitionDate,
    assetNotes,
    assetStatus,
    assetCreatedAt,
    assetUpdatedAt,
    assetDeletedAt,
  ];
}
