import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';

/// An Asset aggregate root — a single item of value a user owns or has
/// owned (mirrors Notes/Goals' standalone-aggregate shape). There is no
/// owning Portfolio/Collection entity; grouping, if ever introduced,
/// happens through the platform Entity Linking Service, not through a
/// field on this entity.
///
/// Business invariants enforced here:
/// - [name] must not be empty and must not exceed 200 characters (mirrors
///   Note/Goal/Task/Habit's title invariant).
/// - [category] must not be empty and must not exceed 100 characters —
///   mirrors Finance's plain-string category pattern (see
///   DOC-031_Finance_Domain_Design.md), not a closed enum.
/// - [value] must never be negative.
/// - [notes] must not exceed 20,000 characters (mirrors `Note.content`).
/// - Status transitions are only permitted per the approved transition
///   table — enforced by [transitionTo], not by direct field mutation
///   (this class has no public status setter).
final class Asset {
  Asset({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.category,
    required this.value,
    required this.acquisitionDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const AssetsException(message: 'Asset name must not be empty');
    }
    if (name.length > 200) {
      throw const AssetsException(
        message: 'Asset name must not exceed 200 characters',
      );
    }
    final trimmedCategory = category.trim();
    if (trimmedCategory.isEmpty) {
      throw const AssetsException(
        message: 'Asset category must not be empty',
      );
    }
    if (category.length > 100) {
      throw const AssetsException(
        message: 'Asset category must not exceed 100 characters',
      );
    }
    if (value < 0) {
      throw const AssetsException(message: 'Asset value must not be negative');
    }
    if (notes.length > 20000) {
      throw const AssetsException(
        message: 'Asset notes must not exceed 20000 characters',
      );
    }
  }

  final AssetId id;
  final String workspaceId;
  final String name;

  /// Free-text category label (e.g. "Electronics", "Vehicle", "Real Estate")
  /// — mirrors Finance's plain-string category, not a closed enum.
  final String category;

  /// The monetary value of this asset. Never negative.
  final double value;

  /// The date this asset was acquired.
  final DateTime acquisitionDate;

  /// Optional free-text notes. Defaults to an empty string.
  final String notes;

  final AssetStatus status;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a copy of this asset with the supplied fields replaced.
  ///
  /// Does not change [status] — use [transitionTo] for status changes.
  /// Mirrors `Note.copyWith` rejecting status as an updatable field.
  Asset copyWith({
    String? name,
    String? category,
    double? value,
    DateTime? acquisitionDate,
    String? notes,
    DateTime? updatedAt,
  }) =>
      Asset(
        id: id,
        workspaceId: workspaceId,
        name: name ?? this.name,
        category: category ?? this.category,
        value: value ?? this.value,
        acquisitionDate: acquisitionDate ?? this.acquisitionDate,
        notes: notes ?? this.notes,
        status: status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Returns a copy of this asset transitioned to [next].
  ///
  /// Throws [AssetsException] if [next] is not reachable from [status] per
  /// the approved transition table:
  ///
  /// ```
  /// active   -> disposed
  /// active   -> archived
  /// disposed -> (none — terminal)
  /// archived -> (none — terminal)
  /// ```
  Asset transitionTo(AssetStatus next, {required DateTime now}) {
    if (!status.canTransitionTo(next)) {
      throw AssetsException(
        message: 'Cannot transition Asset from ${status.name} to ${next.name}',
      );
    }
    return Asset(
      id: id,
      workspaceId: workspaceId,
      name: name,
      category: category,
      value: value,
      acquisitionDate: acquisitionDate,
      notes: notes,
      status: next,
      createdAt: createdAt,
      updatedAt: now,
    );
  }

  /// Entity identity is determined by [id], not by field values.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Asset && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Asset(id: $id, name: $name, status: ${status.name})';
}
