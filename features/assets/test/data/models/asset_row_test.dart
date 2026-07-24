import 'package:feature_assets/src/data/models/asset_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssetRow toMap/fromMap round-trip', () {
    test('round-trips all fields including nullable deletedAt', () {
      final row = AssetRow(
        assetId: 'asset-1',
        workspaceId: 'ws-1',
        name: 'Laptop',
        category: 'Electronics',
        value: 1500.50,
        acquisitionDate: DateTime(2025, 6, 1),
        notes: 'Work laptop',
        status: 'active',
        createdAt: DateTime(2026, 1, 1, 10),
        updatedAt: DateTime(2026, 1, 3, 8),
        deletedAt: null,
      );

      final restored = AssetRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips a soft-deleted row', () {
      final row = AssetRow(
        assetId: 'asset-2',
        workspaceId: 'ws-1',
        name: 'Archived asset',
        category: 'Vehicle',
        value: 5000,
        acquisitionDate: DateTime(2020, 1, 1),
        status: 'archived',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 6),
        deletedAt: DateTime(2026, 1, 7),
      );

      final restored = AssetRow.fromMap(row.toMap());

      expect(restored, row);
    });

    test('round-trips minimal fields (no notes)', () {
      final row = AssetRow(
        assetId: 'asset-3',
        workspaceId: 'ws-1',
        name: 'Minimal',
        category: 'Misc',
        value: 0,
        acquisitionDate: DateTime(2026, 1, 1),
        status: 'active',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final restored = AssetRow.fromMap(row.toMap());

      expect(restored, row);
      expect(restored.notes, '');
      expect(restored.deletedAt, isNull);
    });

    test('decodes a null notes column back to empty string', () {
      final restored = AssetRow.fromMap({
        'asset_id': 'asset-5',
        'workspace_id': 'ws-1',
        'name': 'No extras',
        'category': 'Misc',
        'value': 42,
        'acquisition_date': DateTime(2026, 1, 1).toIso8601String(),
        'notes': null,
        'status': 'active',
        'created_at': DateTime(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime(2026, 1, 1).toIso8601String(),
        'deleted_at': null,
      });

      expect(restored.notes, '');
    });
  });
}
