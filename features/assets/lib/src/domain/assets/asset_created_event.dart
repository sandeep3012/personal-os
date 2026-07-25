import 'package:application/application.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';
import 'package:feature_assets/src/domain/value_objects/asset_status.dart';

final class AssetCreatedEvent extends DomainEvent {
  const AssetCreatedEvent({
    required this.assetId,
    required this.workspaceId,
    required this.name,
    required this.status,
    required this.timestamp,
  });

  final AssetId assetId;
  final String workspaceId;
  final String name;
  final AssetStatus status;
  final DateTime timestamp;
}
