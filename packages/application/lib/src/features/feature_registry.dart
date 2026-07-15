import 'package:application/src/features/feature_metadata.dart';

/// Catalog of all [FeatureMetadata] records registered during application boot.
///
/// [ApplicationModule] registers a [FeatureRegistry] singleton. Each
/// [FeatureModule] calls [register] during its own [register] phase (which
/// runs synchronously, before any async work — see ADR-003 Section 5).
///
/// After boot, the registry is readable by the app shell to discover which
/// features are active, their versions, and descriptions.
final class FeatureRegistry {
  final _features = <String, FeatureMetadata>{};

  /// All registered features, in registration order.
  List<FeatureMetadata> get features =>
      List.unmodifiable(_features.values.toList());

  /// Registers [metadata] for a feature.
  ///
  /// Throws [ArgumentError] if a feature with the same [FeatureMetadata.id]
  /// has already been registered — catches mis-configured modules at boot
  /// rather than silently overwriting.
  void register(FeatureMetadata metadata) {
    if (_features.containsKey(metadata.id)) {
      throw ArgumentError.value(
        metadata.id,
        'metadata.id',
        'A feature with id "${metadata.id}" is already registered.',
      );
    }
    _features[metadata.id] = metadata;
  }

  /// Returns the [FeatureMetadata] for [id], or `null` if not registered.
  FeatureMetadata? find(String id) => _features[id];

  /// Whether a feature with [id] has been registered.
  bool isRegistered(String id) => _features.containsKey(id);

  /// Total number of registered features.
  int get length => _features.length;

  /// Whether no features have been registered.
  bool get isEmpty => _features.isEmpty;

  /// Whether at least one feature has been registered.
  bool get isNotEmpty => _features.isNotEmpty;
}
