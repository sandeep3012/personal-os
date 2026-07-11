import 'package:application/src/permissions/permission_type.dart';
import 'package:platform_core/exceptions/app_exception.dart';

/// Thrown when a required permission is denied or unavailable.
///
/// [permission] optionally identifies the specific [PermissionType] involved.
///
/// Example:
/// ```dart
/// throw const PermissionException(
///   message: 'Camera permission is permanently denied.',
///   permission: PermissionType.camera,
/// );
/// ```
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    this.permission,
    super.cause,
    super.stackTrace,
  });

  /// The permission type involved in the failure, or `null` if not
  /// permission-specific.
  final PermissionType? permission;

  @override
  bool operator ==(Object other) =>
      other is PermissionException &&
      message == other.message &&
      permission == other.permission &&
      cause == other.cause;

  @override
  int get hashCode => Object.hash(runtimeType, message, permission, cause);

  @override
  String toString() {
    final permPart = permission != null ? ', permission: $permission' : '';
    return 'PermissionException(message: $message$permPart)';
  }
}
