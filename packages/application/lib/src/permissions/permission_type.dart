/// The category of a device permission.
///
/// Values map to OS-level permission concepts shared across Android and iOS.
/// Platform implementations of [PermissionService] translate these to the
/// platform-specific permission identifiers.
enum PermissionType {
  /// Access to the device camera.
  camera,

  /// Access to the device microphone.
  microphone,

  /// Access to the device location while the app is in use.
  location,

  /// Access to the device location even when the app is in the background.
  locationAlways,

  /// Access to external storage (Android) or the photo library (iOS).
  storage,

  /// Access to the device contacts.
  contacts,

  /// Access to the device calendar.
  calendar,

  /// Permission to display local or remote notifications.
  notifications,

  /// Permission to use biometric authentication (Face ID, fingerprint).
  biometrics,
}
