import 'dart:convert';
import 'dart:io';

/// Persists whether the user has completed (or skipped past) the first-run
/// onboarding flow, so it is shown at most once (Milestone 6 Part B).
///
/// Mirrors `FileBackedFinanceDatabaseExecutor`'s JSON-file persistence
/// pattern rather than introducing a new dependency (e.g. shared_preferences)
/// for a single boolean flag.
final class OnboardingStatusStore {
  const OnboardingStatusStore(this._file);

  final File _file;

  /// Whether onboarding has already been completed or explicitly skipped.
  /// `false` (including when [_file] doesn't exist yet) means this is the
  /// app's first launch.
  Future<bool> hasCompletedOnboarding() async {
    if (!await _file.exists()) return false;
    final raw = await _file.readAsString();
    if (raw.trim().isEmpty) return false;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded['completed'] as bool? ?? false;
  }

  /// Marks onboarding as completed (whether the user finished it, chose
  /// Start Fresh/Demo Mode, or tapped Skip — every exit path counts as
  /// "done", so onboarding is never shown again this install).
  Future<void> markCompleted() async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(jsonEncode({'completed': true}));
  }
}
