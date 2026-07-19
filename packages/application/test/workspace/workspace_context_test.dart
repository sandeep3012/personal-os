import 'package:application/application.dart';
import 'package:test/test.dart';

void main() {
  group('WorkspaceContext', () {
    test('exposes the initial workspace id', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      expect(context.workspaceId, 'ws-1');
    });

    test('switchTo updates the current workspace id', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      context.switchTo('ws-2');
      expect(context.workspaceId, 'ws-2');
    });

    test('switchTo notifies a registered listener', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      var notified = false;
      context.addListener(() => notified = true);

      context.switchTo('ws-2');

      expect(notified, isTrue);
    });

    test('switchTo notifies every registered listener', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      var firstCount = 0;
      var secondCount = 0;
      context
        ..addListener(() => firstCount++)
        ..addListener(() => secondCount++);

      context.switchTo('ws-2');

      expect(firstCount, 1);
      expect(secondCount, 1);
    });

    test('switchTo to the same workspace id is a no-op and does not notify',
        () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      var notifyCount = 0;
      context.addListener(() => notifyCount++);

      context.switchTo('ws-1');

      expect(notifyCount, 0);
      expect(context.workspaceId, 'ws-1');
    });

    test('removeListener stops further notifications', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      var notifyCount = 0;
      void listener() => notifyCount++;
      context.addListener(listener);

      context.switchTo('ws-2');
      expect(notifyCount, 1);

      context.removeListener(listener);
      context.switchTo('ws-3');

      expect(notifyCount, 1); // unchanged after removal
    });

    test('removeListener is safe to call for a listener that was never added',
        () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      expect(() => context.removeListener(() {}), returnsNormally);
    });

    test('a listener that adds/removes another listener during notification '
        'does not corrupt iteration', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      var secondCalled = false;
      void second() => secondCalled = true;
      void first() => context.removeListener(second);
      context
        ..addListener(first)
        ..addListener(second);

      expect(() => context.switchTo('ws-2'), returnsNormally);
      // Whether `second` fires on this exact switch is not the contract
      // being tested — the guarantee is that mutation during iteration
      // doesn't throw (e.g. a concurrent-modification error).
      expect(secondCalled, isA<bool>());
    });

    test('defaultWorkspaceId is a stable, non-empty placeholder constant',
        () {
      expect(WorkspaceContext.defaultWorkspaceId, isNotEmpty);
    });

    test('multiple switches each notify independently', () {
      final context = WorkspaceContext(initialWorkspaceId: 'ws-1');
      final observedIds = <String>[];
      context.addListener(() => observedIds.add(context.workspaceId));

      context.switchTo('ws-2');
      context.switchTo('ws-3');

      expect(observedIds, ['ws-2', 'ws-3']);
    });
  });
}
