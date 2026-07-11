import 'package:application/src/permissions/permission_status.dart';
import 'package:application/src/permissions/permission_type.dart';

/// Platform-independent contract for checking and requesting device permissions.
///
/// Concrete implementations use platform channels (e.g. `permission_handler`)
/// and are provided by the app layer. Feature packages depend only on this
/// interface.
///
/// Example:
/// ```dart
/// final status = await permissionService.check(PermissionType.camera);
/// if (!status.isGranted) {
///   await permissionService.request(PermissionType.camera);
/// }
/// ```
abstract interface class PermissionService {
  /// Returns the current [PermissionStatus] for [type] without prompting the
  /// user.
  Future<PermissionStatus> check(PermissionType type);

  /// Requests the permission identified by [type].
  ///
  /// Returns the resulting [PermissionStatus] after the user responds to the
  /// system dialog.
  Future<PermissionStatus> request(PermissionType type);

  /// Checks the status of every permission in [types] in a single call.
  ///
  /// Returns a map keyed by [PermissionType] with the current status for each.
  Future<Map<PermissionType, PermissionStatus>> checkAll(
    List<PermissionType> types,
  );
}
