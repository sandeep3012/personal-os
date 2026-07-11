import 'package:application/application.dart';
import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/event_bus/event_bus.dart';
import 'package:platform_runtime/event_bus/i_event_bus.dart';
import 'package:test/test.dart';

// ── Concrete event types ───────────────────────────────────────────────────────

final class _SessionStartedEvent extends AppEvent {
  const _SessionStartedEvent(this.userId);
  final String userId;
}

final class _TransactionRecordedEvent extends DomainEvent {
  const _TransactionRecordedEvent(this.amount);
  final double amount;
}

// ── Tests ──────────────────────────────────────────────────────────────────────

void main() {
  group('AppEvent + EventBus', () {
    late IEventBus bus;

    setUp(() => bus = EventBus());
    tearDown(() => bus.dispose());

    test('AppEvent subclass can be published and received', () {
      _SessionStartedEvent? received;
      final sub = bus.subscribe<_SessionStartedEvent>((e) => received = e);

      bus.publish(const _SessionStartedEvent('user-42'));

      expect(received, isNotNull);
      expect(received!.userId, 'user-42');
      sub.cancel();
    });

    test('subscriber only receives its own AppEvent type', () {
      var count = 0;
      final sub = bus.subscribe<_SessionStartedEvent>((_) => count++);

      bus.publish(const _TransactionRecordedEvent(9.99));
      bus.publish(const _SessionStartedEvent('x'));

      expect(count, 1);
      sub.cancel();
    });
  });

  group('DomainEvent + EventBus', () {
    late IEventBus bus;

    setUp(() => bus = EventBus());
    tearDown(() => bus.dispose());

    test('DomainEvent subclass can be published and received', () {
      _TransactionRecordedEvent? received;
      final sub =
          bus.subscribe<_TransactionRecordedEvent>((e) => received = e);

      bus.publish(const _TransactionRecordedEvent(19.99));

      expect(received, isNotNull);
      expect(received!.amount, 19.99);
      sub.cancel();
    });

    test('subscribeToAll receives both AppEvent and DomainEvent', () {
      final events = <Object>[];
      final sub = bus.subscribeToAll(events.add);

      bus.publish(const _SessionStartedEvent('u1'));
      bus.publish(const _TransactionRecordedEvent(5.0));

      expect(events, hasLength(2));
      expect(events[0], isA<_SessionStartedEvent>());
      expect(events[1], isA<_TransactionRecordedEvent>());
      sub.cancel();
    });

    test('AppEvent and DomainEvent are distinct subscription channels', () {
      final appEvents = <AppEvent>[];
      final domainEvents = <DomainEvent>[];

      final s1 = bus.subscribe<_SessionStartedEvent>(appEvents.add);
      final s2 = bus.subscribe<_TransactionRecordedEvent>(domainEvents.add);

      bus.publish(const _SessionStartedEvent('u'));
      bus.publish(const _TransactionRecordedEvent(1.0));

      expect(appEvents, hasLength(1));
      expect(domainEvents, hasLength(1));
      s1.cancel();
      s2.cancel();
    });
  });

  group('ApplicationModule', () {
    test('registers IEventBus and disposes it on onDispose', () async {
      final module = ApplicationModule();
      final registry = _FakeRegistrar();
      module.register(registry);

      expect(registry.has<IEventBus>(), isTrue);
      final bus = registry.get<IEventBus>();
      expect(bus, isA<EventBus>());

      await module.onDispose();
      // After dispose the bus should be disposed
      expect((bus as EventBus).isDisposed, isTrue);
    });
  });
}

// ── Minimal fake registrar for module test ─────────────────────────────────────

final class _FakeRegistrar implements IDependencyRegistrar {
  final _map = <Type, Object>{};

  @override
  void registerSingleton<T extends Object>(T instance) => _map[T] = instance;

  @override
  void registerLazySingleton<T extends Object>(T Function() f) =>
      _map[T] = f();

  @override
  void registerFactory<T extends Object>(T Function() f) => _map[T] = f();

  bool has<T extends Object>() => _map.containsKey(T);
  T get<T extends Object>() => _map[T] as T;
}
