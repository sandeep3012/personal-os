import 'package:application/application.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';

final class AssetDeletedEvent extends DomainEvent {
  const AssetDeletedEvent({
    required this.assetId,
    required this.workspaceId,
    required this.timestamp,
  });

  final AssetId assetId;
  final String workspaceId;
  final DateTime timestamp;
}
