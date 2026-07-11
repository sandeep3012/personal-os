/// Base class for all application-state objects.
///
/// Concrete state classes extend [AppState] and carry the data relevant to a
/// particular screen or feature. The [AsyncState] specialisation handles the
/// common loading/success/error lifecycle.
///
/// Example:
/// ```dart
/// final class DashboardState extends AppState {
///   const DashboardState({required this.items});
///   final List<DashboardItem> items;
/// }
/// ```
abstract class AppState {
  const AppState();
}
