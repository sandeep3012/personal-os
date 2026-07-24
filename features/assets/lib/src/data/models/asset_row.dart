import 'package:feature_assets/src/data/schema/assets_schema.dart';

/// A single, unmapped row from the `assets` table.
///
/// [AssetRow] is a persistence-layer data shape only — it has no business
/// methods, no validation, and no relationship to the domain `Asset`
/// entity. Mapping between [AssetRow] and `Asset` is a repository-layer
/// concern, not a DAO concern. Mirrors Notes' `NoteRow`.
final class AssetRow {
  const AssetRow({
    required this.assetId,
    required this.workspaceId,
    required this.name,
    required this.category,
    required this.value,
    required this.acquisitionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.deletedAt,
  });

  final String assetId;
  final String workspaceId;
  final String name;
  final String category;
  final double value;
  final DateTime acquisitionDate;
  final String notes;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  /// Builds an [AssetRow] from a raw SQL result row.
  factory AssetRow.fromMap(Map<String, Object?> map) {
    final deletedAtValue = map[AssetsSchema.assetDeletedAt] as String?;
    return AssetRow(
      assetId: map[AssetsSchema.assetId]! as String,
      workspaceId: map[AssetsSchema.assetWorkspaceId]! as String,
      name: map[AssetsSchema.assetName]! as String,
      category: map[AssetsSchema.assetCategory]! as String,
      value: (map[AssetsSchema.assetValue]! as num).toDouble(),
      acquisitionDate:
          DateTime.parse(map[AssetsSchema.assetAcquisitionDate]! as String),
      notes: map[AssetsSchema.assetNotes] as String? ?? '',
      status: map[AssetsSchema.assetStatus]! as String,
      createdAt: DateTime.parse(map[AssetsSchema.assetCreatedAt]! as String),
      updatedAt: DateTime.parse(map[AssetsSchema.assetUpdatedAt]! as String),
      deletedAt: deletedAtValue == null ? null : DateTime.parse(deletedAtValue),
    );
  }

  /// Converts this row to a raw SQL-column map, keyed by [AssetsSchema]
  /// column names.
  Map<String, Object?> toMap() => {
        AssetsSchema.assetId: assetId,
        AssetsSchema.assetWorkspaceId: workspaceId,
        AssetsSchema.assetName: name,
        AssetsSchema.assetCategory: category,
        AssetsSchema.assetValue: value,
        AssetsSchema.assetAcquisitionDate: acquisitionDate.toIso8601String(),
        AssetsSchema.assetNotes: notes,
        AssetsSchema.assetStatus: status,
        AssetsSchema.assetCreatedAt: createdAt.toIso8601String(),
        AssetsSchema.assetUpdatedAt: updatedAt.toIso8601String(),
        AssetsSchema.assetDeletedAt: deletedAt?.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetRow &&
          other.assetId == assetId &&
          other.workspaceId == workspaceId &&
          other.name == name &&
          other.category == category &&
          other.value == value &&
          other.acquisitionDate == acquisitionDate &&
          other.notes == notes &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.deletedAt == deletedAt);

  @override
  int get hashCode => Object.hash(
        assetId,
        workspaceId,
        name,
        category,
        value,
        acquisitionDate,
        notes,
        status,
        createdAt,
        updatedAt,
        deletedAt,
      );

  @override
  String toString() => 'AssetRow(assetId: $assetId, name: $name)';
}
