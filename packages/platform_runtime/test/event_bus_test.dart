import 'package:platform_runtime/event_bus/event_bus.dart';
import 'package:platform_runtime/event_bus/event_subscription.dart';
import 'package:platform_runtime/event_bus/i_event.dart';
import 'package:test/test.dart';

// ── Test events ──────────────────────────────────────────────────────────────

final class CounterEvent extends IEvent {
  const CounterEvent(this.value);
  final int value;
}

final class OtherEvent extends IEvent {
  const OtherEvent(this.label);
  final String label;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late EventBus bus;

  setUp(() => bus = EventBus());
  tearDown(() {
    if (!bus.isDisposed) bus.dispose();
  });

  group('EventBus — subscribe / publish', () {
    test('subscriber receives published event', () {
      final received = <int>[];
      bus.subscribe<CounterEvent>((e) => received.add(e.value));

      bus.publish(const CounterEvent(1));
      bus.publish(const CounterEvent(2));

      expect(received, [1, 2]);
    });

    test('subscriber only receives its own event type', () {
      final counter = <int>[];
      final other = <String>[];

      bus.subscribe<CounterEvent>((e) => counter.add(e.value));
      bus.subscribe<OtherEvent>((e) => other.add(e.label));

      bus.publish(const CounterEvent(42));
      bus.publish(const OtherEvent('hello'));

      expect(counter, [42]);
      expect(other, ['hello']);
    });

    test('multiple subscribers on the same type all receive the event', () {
      final a = <int>[];
      final b = <int>[];

      bus.subscribe<CounterEvent>((e) => a.add(e.value));
      bus.subscribe<CounterEvent>((e) => b.add(e.value));

      bus.publish(const CounterEvent(7));

      expect(a, [7]);
      expect(b, [7]);
    });

    test('delivery is synchronous', () {
      final log = <String>[];

      bus.subscribe<CounterEvent>((e) => log.add('handler:${e.value}'));

      log.add('before');
      bus.publish(const CounterEvent(1));
      log.add('after');

      expect(log, ['before', 'handler:1', 'after']);
    });
  });

  group('EventBus — subscribeToAll', () {
    test('receives every event regardless of type', () {
      final received = <IEvent>[];
      bus.subscribeToAll(received.add);

      bus.publish(const CounterEvent(1));
      bus.publish(const OtherEvent('x'));

      expect(received, hasLength(2));
      expect(received[0], isA<CounterEvent>());
      expect(received[1], isA<OtherEvent>());
    });
  });

  group('EventBus — unsubscribe', () {
    test('cancelled subscription no longer receives events', () {
      final received = <int>[];
      final sub = bus.subscribe<CounterEvent>((e) => received.add(e.value));

      bus.publish(const CounterEvent(1));
      sub.cancel();
      bus.publish(const CounterEvent(2));

      expect(received, [1]);
    });

    test('cancel is idempotent', () {
      final sub = bus.subscribe<CounterEvent>((_) {});
      expect(() {
        sub.cancel();
        sub.cancel();
      }, returnsNormally);
    });

    test('cancelling one subscription does not affect others', () {
      final a = <int>[];
      final b = <int>[];

      final subA = bus.subscribe<CounterEvent>((e) => a.add(e.value));
      bus.subscribe<CounterEvent>((e) => b.add(e.value));

      bus.publish(const CounterEvent(1));
      subA.cancel();
      bus.publish(const CounterEvent(2));

      expect(a, [1]);
      expect(b, [1, 2]);
    });
  });

  group('EventBus — EventSubscription', () {
    test('StreamEventSubscription wraps a raw subscription', () {
      // verify the concrete class is returned by subscribe
      final sub = bus.subscribe<CounterEvent>((_) {});
      expect(sub, isA<EventSubscription>());
      sub.cancel();
    });
  });

  group('EventBus — dispose', () {
    test('publish after dispose is a no-op (does not throw)', () {
      bus.dispose();
      expect(() => bus.publish(const CounterEvent(1)), returnsNormally);
    });

    test('subscribe after dispose throws StateError', () {
      bus.dispose();
      expect(
        () => bus.subscribe<CounterEvent>((_) {}),
        throwsStateError,
      );
    });

    test('subscribeToAll after dispose throws StateError', () {
      bus.dispose();
      expect(
        () => bus.subscribeToAll((_) {}),
        throwsStateError,
      );
    });

    test('dispose is idempotent', () {
      expect(() {
        bus.dispose();
        bus.dispose();
      }, returnsNormally);
    });

    test('isDisposed reflects state correctly', () {
      expect(bus.isDisposed, isFalse);
      bus.dispose();
      expect(bus.isDisposed, isTrue);
    });
  });
}
