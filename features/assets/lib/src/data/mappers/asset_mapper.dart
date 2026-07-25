import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';

/// Converts between the domain [Asset] entity and the persistence
/// [AssetRow] model. Pure conversion only — no validation, no repository
/// calls, no SQL, no business rules. Mirrors Notes' `NoteMapper`.
///
/// [Asset] never represents a soft-deleted row: [AssetDao]'s read methods
/// already exclude soft-deleted rows (`deleted_at IS NULL`), so a domain
/// [Asset] instance can never have been loaded from a deleted row in the
/// first place. Consequently [toRow] always sets [AssetRow.deletedAt] to
/// `null`.
final class AssetMapper {
  const AssetMapper();

  /// Converts a persisted [AssetRow] to a domain [Asset].
  ///
  /// Throws [AssetsException] if [AssetRow.status] does not correspond
  /// to a value this mapper recognizes — corrupted or unsupported
  /// persisted data must fail loudly rather than be silently coerced.
  Asset toEntity(AssetRow row) {
    return Asset(
      id: AssetId(row.assetId),
      workspaceId: row.workspaceId,
      name: row.name,
      category: row.category,
      value: row.value,
      acquisitionDate: row.acquisitionDate,
      notes: row.notes,
      status: _statusFromColumnValue(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Converts a domain [Asset] to a persistable [AssetRow].
  AssetRow toRow(Asset asset) {
    return AssetRow(
      assetId: asset.id.value,
      workspaceId: asset.workspaceId,
      name: asset.name,
      category: asset.category,
      value: asset.value,
      acquisitionDate: asset.acquisitionDate,
      notes: asset.notes,
      status: asset.status.name,
      createdAt: asset.createdAt,
      updatedAt: asset.updatedAt,
      deletedAt: null,
    );
  }

  AssetStatus _statusFromColumnValue(String value) {
    for (final status in AssetStatus.values) {
      if (status.name == value) return status;
    }
    throw AssetsException(
      message: 'Unrecognized status value persisted: "$value"',
    );
  }
}
