import 'package:feature_assets/src/domain/assets/asset_archived_event.dart';
import 'package:feature_assets/src/domain/assets/asset_created_event.dart';
import 'package:feature_assets/src/domain/assets/asset_deleted_event.dart';
import 'package:feature_assets/src/domain/assets/asset_disposed_event.dart';
import 'package:feature_assets/src/domain/assets/asset_updated_event.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _ws = 'ws-1';

void main() {
  final now = DateTime(2026, 1, 1);

  test('AssetCreatedEvent carries its fields', () {
    final event = AssetCreatedEvent(
      assetId: const AssetId('asset-1'),
      workspaceId: _ws,
      name: 'Name',
      status: AssetStatus.active,
      timestamp: now,
    );
    expect(event.assetId, const AssetId('asset-1'));
    expect(event.name, 'Name');
    expect(event.status, AssetStatus.active);
  });

  test('AssetUpdatedEvent carries its fields', () {
    final event = AssetUpdatedEvent(
      assetId: const AssetId('asset-1'),
      workspaceId: _ws,
      name: 'Name',
      status: AssetStatus.active,
      timestamp: now,
    );
    expect(event.name, 'Name');
  });

  test('AssetArchivedEvent carries its fields', () {
    final event = AssetArchivedEvent(
      assetId: const AssetId('asset-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.assetId, const AssetId('asset-1'));
    expect(event.workspaceId, _ws);
  });

  test('AssetDisposedEvent carries its fields', () {
    final event = AssetDisposedEvent(
      assetId: const AssetId('asset-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.assetId, const AssetId('asset-1'));
    expect(event.workspaceId, _ws);
  });

  test('AssetDeletedEvent carries its fields', () {
    final event = AssetDeletedEvent(
      assetId: const AssetId('asset-1'),
      workspaceId: _ws,
      timestamp: now,
    );
    expect(event.timestamp, now);
  });
}
