import 'package:feature_documents/src/domain/value_objects/document_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentStatusTransitions', () {
    test('active can transition to archived', () {
      expect(DocumentStatus.active.canTransitionTo(DocumentStatus.archived), isTrue);
    });

    test('archived cannot transition anywhere', () {
      expect(DocumentStatus.archived.allowedNextStatuses, isEmpty);
      expect(DocumentStatus.archived.canTransitionTo(DocumentStatus.active), isFalse);
    });

    test('active cannot transition to itself', () {
      expect(DocumentStatus.active.canTransitionTo(DocumentStatus.active), isFalse);
    });
  });
}
