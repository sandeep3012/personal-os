import 'package:feature_assets/src/domain/entities/asset.dart';
import 'package:feature_assets/src/domain/exceptions/assets_exception.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

Asset _asset({
  String name = 'Name',
  String category = 'Electronics',
  double value = 100,
  DateTime? acquisitionDate,
  String notes = '',
  AssetStatus status = AssetStatus.active,
}) {
  final now = DateTime(2026, 1, 1);
  return Asset(
    id: const AssetId('asset-1'),
    workspaceId: _ws,
    name: name,
    category: category,
    value: value,
    acquisitionDate: acquisitionDate ?? DateTime(2025, 1, 1),
    notes: notes,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Asset construction', () {
    test('rejects an empty name', () {
      expect(() => _asset(name: '   '), throwsA(isA<AssetsException>()));
    });

    test('rejects a name longer than 200 characters', () {
      expect(() => _asset(name: 'a' * 201), throwsA(isA<AssetsException>()));
    });

    test('rejects an empty category', () {
      expect(() => _asset(category: '   '), throwsA(isA<AssetsException>()));
    });

    test('rejects a category longer than 100 characters', () {
      expect(
        () => _asset(category: 'a' * 101),
        throwsA(isA<AssetsException>()),
      );
    });

    test('rejects a negative value', () {
      expect(() => _asset(value: -1), throwsA(isA<AssetsException>()));
    });

    test('rejects notes longer than 20000 characters', () {
      expect(
        () => _asset(notes: 'a' * 20001),
        throwsA(isA<AssetsException>()),
      );
    });

    test('accepts a zero value', () {
      expect(() => _asset(value: 0), returnsNormally);
    });

    test('defaults notes to empty string', () {
      final asset = _asset();
      expect(asset.notes, '');
    });
  });

  group('Asset.copyWith', () {
    test('replaces only the supplied fields', () {
      final asset = _asset(name: 'Original', category: 'Vehicle');
      final updated = asset.copyWith(name: 'Renamed');

      expect(updated.name, 'Renamed');
      expect(updated.category, 'Vehicle');
      expect(updated.status, asset.status);
    });

    test('never changes status', () {
      final asset = _asset();
      final updated = asset.copyWith(name: 'X');
      expect(updated.status, AssetStatus.active);
    });
  });

  group('Asset.transitionTo', () {
    test('allows active -> disposed', () {
      final asset = _asset();
      final disposed =
          asset.transitionTo(AssetStatus.disposed, now: DateTime(2026, 2, 1));

      expect(disposed.status, AssetStatus.disposed);
      expect(disposed.updatedAt, DateTime(2026, 2, 1));
    });

    test('allows active -> archived', () {
      final asset = _asset();
      final archived =
          asset.transitionTo(AssetStatus.archived, now: DateTime(2026, 2, 1));

      expect(archived.status, AssetStatus.archived);
      expect(archived.updatedAt, DateTime(2026, 2, 1));
    });

    test('rejects archived -> archived', () {
      final asset = _asset(status: AssetStatus.archived);
      expect(
        () => asset.transitionTo(AssetStatus.archived, now: DateTime(2026, 2, 1)),
        throwsA(isA<AssetsException>()),
      );
    });

    test('rejects disposed -> active', () {
      final asset = _asset(status: AssetStatus.disposed);
      expect(
        () => asset.transitionTo(AssetStatus.active, now: DateTime(2026, 2, 1)),
        throwsA(isA<AssetsException>()),
      );
    });
  });

  group('Asset equality', () {
    test('two assets with the same id are equal regardless of other fields', () {
      final a = _asset(name: 'A');
      final b = _asset(name: 'B');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
