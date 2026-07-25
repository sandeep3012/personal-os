import 'package:application/application.dart';
import 'package:feature_assets/src/domain/value_objects/asset_id.dart';

/// Archiving is a distinct, terminal, business-meaningful transition,
/// not an ordinary field update — mirrors `NoteArchivedEvent`.
final class AssetArchivedEvent extends DomainEvent {
  const AssetArchivedEvent({
    required this.assetId,
    required this.workspaceId,
    required this.timestamp,
  });

  final AssetId assetId;
  final String workspaceId;
  final DateTime timestamp;
}
