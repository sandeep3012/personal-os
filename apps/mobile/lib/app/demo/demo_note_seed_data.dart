import 'package:feature_notes/notes.dart';

/// Seeds a fresh [INoteDatabaseExecutor] with realistic Notes sample data
/// for Demo Mode. Mirrors `DemoGoalSeedData`/`DemoHabitSeedData` exactly —
/// writes directly via `INSERT INTO ...`, the same seam `apps/mobile`'s own
/// bootstrap tests use, since `feature_notes`'s internal schema/DAO classes
/// aren't part of its public barrel.
abstract final class DemoNoteSeedData {
  /// Inserts a realistic demo dataset into [executor] for [workspaceId]: a
  /// mix of active notes and one archived note — archiving is a user
  /// action, but including one demonstrates the "archived notes are hidden
  /// from the list" behavior in Demo Mode too.
  static Future<void> seed(
    INoteDatabaseExecutor executor, {
    required String workspaceId,
  }) async {
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    var seq = 0;
    String nextId() => 'demo-note-${++seq}';

    // Mirrors NoteRow's pipe-delimited tag encoding — `|tag1|tag2|`, or an
    // empty string when there are no tags.
    String encodeTags(List<String> tags) =>
        tags.isEmpty ? '' : '|${tags.join('|')}|';

    Future<void> insertNote({
      required String title,
      String content = '',
      List<String> tags = const [],
      String status = 'active',
    }) =>
        executor.execute(
          'INSERT INTO notes '
          '(note_id, workspace_id, title, content, tags, status, '
          'created_at, updated_at, deleted_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            nextId(),
            workspaceId,
            title,
            content,
            encodeTags(tags),
            status,
            createdAt,
            createdAt,
            null,
          ],
        );

    await insertNote(
      title: 'Grocery list',
      content: 'Milk, eggs, bread, spinach, coffee beans',
      tags: ['errands', 'home'],
    );
    await insertNote(
      title: 'Project kickoff notes',
      content: 'Discussed scope, timeline, and initial milestones with '
          'the team.',
      tags: ['work'],
    );
    await insertNote(
      title: 'Book recommendations',
      content: 'Project Hail Mary, The Three-Body Problem, Piranesi',
      tags: ['reading'],
    );
    await insertNote(
      title: 'Trip packing list',
      content: 'Passport, chargers, hiking boots, sunscreen',
      tags: ['travel', 'errands'],
    );
    await insertNote(
      title: 'Old meeting notes',
      content: 'Archived after the project wrapped up.',
      status: 'archived',
    );
  }
}
