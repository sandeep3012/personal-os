import 'dart:math';

/// Abstract contract for unique ID generation.
///
/// Inject this interface wherever IDs are created so that tests can provide
/// deterministic IDs without relying on real random generation.
abstract interface class IdGenerator {
  /// Generates and returns a new unique identifier string.
  String generate();
}

/// UUID v4 generator backed by [Random.secure].
///
/// Produces RFC 4122 compliant v4 UUIDs in the canonical lower-case
/// `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` format.
///
/// Example:
/// ```dart
/// final gen = UuidGenerator();
/// final id = gen.generate(); // 'a1b2c3d4-e5f6-4789-8abc-def012345678'
/// ```
final class UuidGenerator implements IdGenerator {
  const UuidGenerator();

  static final Random _rng = Random.secure();

  @override
  String generate() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    // Set version 4 bits (high nibble of byte 6)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    // Set variant bits (high 2 bits of byte 8)
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}
