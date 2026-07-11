import 'package:platform_runtime/registry/registry_exception.dart';
import 'package:platform_runtime/registry/service_registry.dart';
import 'package:test/test.dart';

// ── Test abstractions ─────────────────────────────────────────────────────────

abstract interface class ICounter {
  int get value;
}

final class Counter implements ICounter {
  Counter([this.value = 0]);
  @override
  final int value;
}

abstract interface class ILogger {
  void log(String msg);
}

final class FakeLogger implements ILogger {
  final messages = <String>[];
  @override
  void log(String msg) => messages.add(msg);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late ServiceRegistry registry;

  setUp(() => registry = ServiceRegistry());

  group('ServiceRegistry — registerSingleton', () {
    test('get returns the exact registered instance', () {
      final instance = Counter(10);
      registry.registerSingleton<ICounter>(instance);
      expect(registry.get<ICounter>(), same(instance));
    });

    test('get always returns the same instance', () {
      registry.registerSingleton<ICounter>(Counter(1));
      expect(registry.get<ICounter>(), same(registry.get<ICounter>()));
    });

    test('duplicate registration throws RegistryException', () {
      registry.registerSingleton<ICounter>(Counter());
      expect(
        () => registry.registerSingleton<ICounter>(Counter()),
        throwsA(isA<RegistryException>()),
      );
    });
  });

  group('ServiceRegistry — registerFactory', () {
    test('get invokes factory each time', () {
      var callCount = 0;
      registry.registerFactory<ICounter>(() {
        callCount++;
        return Counter(callCount);
      });

      final first = registry.get<ICounter>();
      final second = registry.get<ICounter>();

      expect(callCount, 2);
      expect(first.value, 1);
      expect(second.value, 2);
      expect(first, isNot(same(second)));
    });

    test('duplicate registration throws RegistryException', () {
      registry.registerFactory<ICounter>(Counter.new);
      expect(
        () => registry.registerFactory<ICounter>(Counter.new),
        throwsA(isA<RegistryException>()),
      );
    });
  });

  group('ServiceRegistry — registerLazySingleton', () {
    test('factory is called only once', () {
      var callCount = 0;
      registry.registerLazySingleton<ICounter>(() {
        callCount++;
        return Counter(99);
      });

      registry.get<ICounter>();
      registry.get<ICounter>();

      expect(callCount, 1);
    });

    test('get returns the same cached instance', () {
      registry.registerLazySingleton<ICounter>(Counter.new);
      expect(registry.get<ICounter>(), same(registry.get<ICounter>()));
    });

    test('factory is not called until first get', () {
      var called = false;
      registry.registerLazySingleton<ICounter>(() {
        called = true;
        return Counter();
      });
      expect(called, isFalse);
      registry.get<ICounter>();
      expect(called, isTrue);
    });

    test('duplicate registration throws RegistryException', () {
      registry.registerLazySingleton<ICounter>(Counter.new);
      expect(
        () => registry.registerLazySingleton<ICounter>(Counter.new),
        throwsA(isA<RegistryException>()),
      );
    });
  });

  group('ServiceRegistry — get', () {
    test('throws RegistryException for unregistered type', () {
      expect(
        () => registry.get<ICounter>(),
        throwsA(isA<RegistryException>()),
      );
    });

    test('multiple types can be registered independently', () {
      registry.registerSingleton<ICounter>(Counter(5));
      registry.registerSingleton<ILogger>(FakeLogger());

      expect(registry.get<ICounter>().value, 5);
      expect(registry.get<ILogger>(), isA<FakeLogger>());
    });
  });

  group('ServiceRegistry — isRegistered / contains', () {
    test('returns false before registration', () {
      expect(registry.isRegistered<ICounter>(), isFalse);
      expect(registry.contains<ICounter>(), isFalse);
    });

    test('returns true after registerSingleton', () {
      registry.registerSingleton<ICounter>(Counter());
      expect(registry.isRegistered<ICounter>(), isTrue);
      expect(registry.contains<ICounter>(), isTrue);
    });

    test('returns true after registerFactory', () {
      registry.registerFactory<ICounter>(Counter.new);
      expect(registry.isRegistered<ICounter>(), isTrue);
    });

    test('returns true after registerLazySingleton', () {
      registry.registerLazySingleton<ICounter>(Counter.new);
      expect(registry.isRegistered<ICounter>(), isTrue);
    });
  });

  group('ServiceRegistry — unregister', () {
    test('removes singleton registration', () {
      registry.registerSingleton<ICounter>(Counter());
      registry.unregister<ICounter>();
      expect(registry.isRegistered<ICounter>(), isFalse);
    });

    test('allows re-registration after unregister', () {
      registry.registerSingleton<ICounter>(Counter(1));
      registry.unregister<ICounter>();
      registry.registerSingleton<ICounter>(Counter(2));
      expect(registry.get<ICounter>().value, 2);
    });

    test('unregister of lazy singleton clears cached value', () {
      var callCount = 0;
      registry.registerLazySingleton<ICounter>(() {
        callCount++;
        return Counter(callCount);
      });
      registry.get<ICounter>(); // triggers creation
      registry.unregister<ICounter>();

      registry.registerLazySingleton<ICounter>(() {
        callCount++;
        return Counter(callCount);
      });
      final result = registry.get<ICounter>();
      expect(callCount, 2);
      expect(result.value, 2);
    });

    test('safe to unregister a type that was never registered', () {
      expect(() => registry.unregister<ICounter>(), returnsNormally);
    });
  });

  group('ServiceRegistry — reset', () {
    test('clears all registrations', () {
      registry.registerSingleton<ICounter>(Counter());
      registry.registerFactory<ILogger>(FakeLogger.new);
      registry.reset();

      expect(registry.isRegistered<ICounter>(), isFalse);
      expect(registry.isRegistered<ILogger>(), isFalse);
    });

    test('allows fresh registrations after reset', () {
      registry.registerSingleton<ICounter>(Counter(1));
      registry.reset();
      registry.registerSingleton<ICounter>(Counter(2));
      expect(registry.get<ICounter>().value, 2);
    });
  });
}
