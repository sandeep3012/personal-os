import 'package:feature_calendar/calendar.dart';

/// Seeds a fresh [IEventDatabaseExecutor] with realistic Calendar sample
/// data for Demo Mode. Mirrors `DemoNoteSeedData`/`DemoGoalSeedData`
/// exactly — writes directly via `INSERT INTO ...`, the same seam
/// `apps/mobile`'s own bootstrap tests use, since `feature_calendar`'s
/// internal schema/DAO classes aren't part of its public barrel.
abstract final class DemoCalendarSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of upcoming active events and one archived event — archiving is a
  /// user action, but including one demonstrates the "archived events are
  /// hidden from the list" behavior in Demo Mode too.
  static Future<void> seed(
    IEventDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-event-${++seq}';

    Future<void> insertEvent({
      required String title,
      required DateTime start,
      required DateTime end,
      String location = '',
      String description = '',
      String status = 'active',
    }) =>
        executor.execute(
          'INSERT INTO events '
          '(event_id, workspace_id, title, description, location, '
          'start_time, end_time, status, created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            title,
            description,
            location,
            start.toIso8601String(),
            end.toIso8601String(),
            status,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertEvent(
      title: 'Team standup',
      start: now.add(const Duration(days: 1, hours: 1)),
      end: now.add(const Duration(days: 1, hours: 1, minutes: 30)),
      location: 'Conference Room A',
      description: 'Daily sync with the team.',
    );
    await insertEvent(
      title: 'Dentist appointment',
      start: now.add(const Duration(days: 3, hours: 4)),
      end: now.add(const Duration(days: 3, hours: 5)),
      location: 'Downtown Dental',
    );
    await insertEvent(
      title: 'Project review',
      start: now.add(const Duration(days: 5, hours: 2)),
      end: now.add(const Duration(days: 5, hours: 3)),
      description: 'Quarterly project review with stakeholders.',
    );
    await insertEvent(
      title: "Friend's birthday party",
      start: now.add(const Duration(days: 7, hours: 6)),
      end: now.add(const Duration(days: 7, hours: 9)),
      location: "Sam's place",
    );
    await insertEvent(
      title: 'Old planning meeting',
      start: now.subtract(const Duration(days: 10, hours: 2)),
      end: now.subtract(const Duration(days: 10, hours: 1)),
      status: 'archived',
    );
  }
}
