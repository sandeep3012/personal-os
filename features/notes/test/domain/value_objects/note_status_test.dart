import 'package:feature_notes/src/domain/value_objects/note_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteStatusTransitions', () {
    test('active can transition to archived', () {
      expect(NoteStatus.active.canTransitionTo(NoteStatus.archived), isTrue);
    });

    test('archived cannot transition anywhere', () {
      expect(NoteStatus.archived.allowedNextStatuses, isEmpty);
      expect(NoteStatus.archived.canTransitionTo(NoteStatus.active), isFalse);
    });

    test('active cannot transition to itself', () {
      expect(NoteStatus.active.canTransitionTo(NoteStatus.active), isFalse);
    });
  });
}
