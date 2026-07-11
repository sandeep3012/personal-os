/// The current status of a device permission.
enum PermissionStatus {
  /// The permission has been granted by the user.
  granted,

  /// The permission has been denied by the user but can be re-requested.
  denied,

  /// The permission is restricted by the OS or parental controls and cannot
  /// be changed by the user.
  restricted,

  /// The user has permanently denied the permission; the app must direct the
  /// user to the system settings to change it.
  permanentlyDenied,

  /// The permission status is not yet known (e.g. not yet requested).
  unknown,
}

/// Convenience extensions on [PermissionStatus].
extension PermissionStatusX on PermissionStatus {
  /// Whether the permission allows the corresponding feature to be used.
  bool get isGranted => this == PermissionStatus.granted;

  /// Whether the permission has been denied in any form.
  bool get isDenied =>
      this == PermissionStatus.denied ||
      this == PermissionStatus.permanentlyDenied ||
      this == PermissionStatus.restricted;
}
