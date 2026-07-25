import 'package:feature_assets/src/data/mappers/asset_mapper.dart';
import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = AssetMapper();

  Asset asset({
    String id = 'asset-1',
    String name = 'Laptop',
    String category = 'Electronics',
    double value = 1500,
    String notes = 'Work laptop',
    AssetStatus status = AssetStatus.active,
  }) {
    final now = DateTime(2024, 1, 1, 10, 30);
    return Asset(
      id: AssetId(id),
      workspaceId: 'ws-1',
      name: name,
      category: category,
      value: value,
      acquisitionDate: DateTime(2024, 1, 2),
      notes: notes,
      status: status,
      createdAt: now,
      updatedAt: DateTime(2024, 2, 1, 8),
    );
  }

  group('AssetMapper.toRow', () {
    test('maps all scalar fields', () {
      final row = mapper.toRow(asset(id: 'asset-1', name: 'Laptop'));

      expect(row.assetId, 'asset-1');
      expect(row.workspaceId, 'ws-1');
      expect(row.name, 'Laptop');
      expect(row.category, 'Electronics');
      expect(row.value, 1500);
      expect(row.acquisitionDate, DateTime(2024, 1, 2));
      expect(row.notes, 'Work laptop');
    });

    test('maps every AssetStatus to its enum name', () {
      for (final status in AssetStatus.values) {
        final row = mapper.toRow(asset(status: status));
        expect(row.status, status.name);
      }
    });

    test('always maps deletedAt to null (domain Asset is never soft-deleted)',
        () {
      final row = mapper.toRow(asset());
      expect(row.deletedAt, isNull);
    });

    test('preserves Unicode content', () {
      final row = mapper.toRow(asset(name: 'Café table ☕ 買い物'));
      expect(row.name, 'Café table ☕ 買い物');
    });
  });

  group('AssetMapper.toEntity', () {
    AssetRow row({
      String id = 'asset-1',
      String name = 'Laptop',
      String status = 'active',
    }) {
      final now = DateTime(2024, 1, 1, 10, 30);
      return AssetRow(
        assetId: id,
        workspaceId: 'ws-1',
        name: name,
        category: 'Electronics',
        value: 1500,
        acquisitionDate: DateTime(2024, 1, 2),
        notes: 'Work laptop',
        status: status,
        createdAt: now,
        updatedAt: DateTime(2024, 2, 1, 8),
      );
    }

    test('maps all scalar fields', () {
      final entity = mapper.toEntity(row(id: 'asset-2', name: 'Monitor'));

      expect(entity.id, const AssetId('asset-2'));
      expect(entity.workspaceId, 'ws-1');
      expect(entity.name, 'Monitor');
      expect(entity.acquisitionDate, DateTime(2024, 1, 2));
    });

    test('converts every status column value back to its enum', () {
      for (final status in AssetStatus.values) {
        final entity = mapper.toEntity(row(status: status.name));
        expect(entity.status, status);
      }
    });

    test('throws AssetsException for an unrecognized status value', () {
      expect(
        () => mapper.toEntity(row(status: 'not_a_real_status')),
        throwsA(isA<AssetsException>()),
      );
    });
  });

  group('AssetMapper round-trip', () {
    test('Asset -> AssetRow -> Asset preserves all domain fields', () {
      final original = asset(
        id: 'asset-rt',
        name: 'Round Trip',
        status: AssetStatus.active,
      );

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.id, original.id);
      expect(restored.workspaceId, original.workspaceId);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.value, original.value);
      expect(restored.acquisitionDate, original.acquisitionDate);
      expect(restored.notes, original.notes);
      expect(restored.status, original.status);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('round-trips a disposed asset', () {
      final original = asset(status: AssetStatus.disposed);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, AssetStatus.disposed);
    });

    test('round-trips an archived asset', () {
      final original = asset(status: AssetStatus.archived);

      final restored = mapper.toEntity(mapper.toRow(original));

      expect(restored.status, AssetStatus.archived);
    });
  });
}
