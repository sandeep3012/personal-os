import 'package:platform_core/di/i_dependency_registrar.dart';
import 'package:platform_runtime/bootstrap/runtime_bootstrap.dart';
import 'package:platform_runtime/bootstrap/runtime_exception.dart';
import 'package:platform_runtime/modules/runtime_module.dart';
import 'package:test/test.dart';

// ── Test modules ──────────────────────────────────────────────────────────────

abstract interface class IGreeter {
  String greet(String name);
}

final class SimpleGreeter implements IGreeter {
  @override
  String greet(String name) => 'Hello, $name!';
}

final class GreeterModule extends RuntimeModule {
  @override
  void register(IDependencyRegistrar registrar) {
    registrar.registerSingleton<IGreeter>(SimpleGreeter());
  }
}

/// Tracks the order in which lifecycle hooks are called.
final class OrderTrackingModule extends RuntimeModule {
  OrderTrackingModule(this.name, this.log);

  final String name;
  final List<String> log;

  @override
  void register(IDependencyRegistrar registrar) => log.add('$name.register');

  @override
  Future<void> onInit() async => log.add('$name.onInit');

  @override
  Future<void> onStart() async => log.add('$name.onStart');

  @override
  Future<void> onStop() async => log.add('$name.onStop');

  @override
  Future<void> onDispose() async => log.add('$name.onDispose');
}

/// Fails during a specified lifecycle hook.
final class FailingModule extends RuntimeModule {
  FailingModule({required this.failOn});
  final String failOn;

  @override
  void register(IDependencyRegistrar registrar) {
    if (failOn == 'register') throw Exception('register failed');
  }

  @override
  Future<void> onInit() async {
    if (failOn == 'onInit') throw Exception('onInit failed');
  }

  @override
  Future<void> onStart() async {
    if (failOn == 'onStart') throw Exception('onStart failed');
  }

  @override
  Future<void> onStop() async {
    if (failOn == 'onStop') throw Exception('onStop failed');
  }

  @override
  Future<void> onDispose() async {
    if (failOn == 'onDispose') throw Exception('onDispose failed');
  }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late RuntimeBootstrap bootstrap;

  setUp(() => bootstrap = RuntimeBootstrap());

  group('RuntimeBootstrap — initial state', () {
    test('isBooted starts false', () => expect(bootstrap.isBooted, isFalse));
    test(
      'isShutdown starts false',
      () => expect(bootstrap.isShutdown, isFalse),
    );
  });

  group('RuntimeBootstrap — module registration', () {
    test('module register() populates the service registry', () async {
      bootstrap.addModule(GreeterModule());
      await bootstrap.boot();

      final greeter = bootstrap.registry.get<IGreeter>();
      expect(greeter.greet('World'), 'Hello, World!');
    });

    test('addModule after boot throws RuntimeException', () async {
      await bootstrap.boot();
      expect(
        () => bootstrap.addModule(GreeterModule()),
        throwsA(isA<RuntimeException>()),
      );
    });
  });

  group('RuntimeBootstrap — boot', () {
    test('boot with no modules completes without error', () async {
      await expectLater(bootstrap.boot(), completes);
      expect(bootstrap.isBooted, isTrue);
    });

    test('boot calls hooks in order: register → onInit → onStart', () async {
      final log = <String>[];
      bootstrap.addModule(OrderTrackingModule('A', log));
      await bootstrap.boot();

      expect(log, ['A.register', 'A.onInit', 'A.onStart']);
    });

    test('multiple modules: all registers before any onInit', () async {
      final log = <String>[];
      bootstrap
        ..addModule(OrderTrackingModule('A', log))
        ..addModule(OrderTrackingModule('B', log));
      await bootstrap.boot();

      expect(log, [
        'A.register',
        'B.register',
        'A.onInit',
        'B.onInit',
        'A.onStart',
        'B.onStart',
      ]);
    });

    test('calling boot twice throws RuntimeException', () async {
      await bootstrap.boot();
      expect(() => bootstrap.boot(), throwsA(isA<RuntimeException>()));
    });

    test('module register failure wraps in RuntimeException', () async {
      bootstrap.addModule(FailingModule(failOn: 'register'));
      await expectLater(
        bootstrap.boot(),
        throwsA(isA<RuntimeException>()),
      );
    });

    test('module onInit failure wraps in RuntimeException', () async {
      bootstrap.addModule(FailingModule(failOn: 'onInit'));
      await expectLater(
        bootstrap.boot(),
        throwsA(isA<RuntimeException>()),
      );
    });

    test('module onStart failure wraps in RuntimeException', () async {
      bootstrap.addModule(FailingModule(failOn: 'onStart'));
      await expectLater(
        bootstrap.boot(),
        throwsA(isA<RuntimeException>()),
      );
    });
  });

  group('RuntimeBootstrap — shutdown', () {
    test('shutdown calls onStop → onDispose in reverse registration order',
        () async {
      final log = <String>[];
      bootstrap
        ..addModule(OrderTrackingModule('A', log))
        ..addModule(OrderTrackingModule('B', log));
      await bootstrap.boot();
      log.clear();
      await bootstrap.shutdown();

      expect(log, [
        'B.onStop',
        'A.onStop',
        'B.onDispose',
        'A.onDispose',
      ]);
    });

    test('isShutdown becomes true after shutdown', () async {
      await bootstrap.boot();
      await bootstrap.shutdown();
      expect(bootstrap.isShutdown, isTrue);
    });

    test('shutdown before boot throws RuntimeException', () async {
      await expectLater(
        bootstrap.shutdown(),
        throwsA(isA<RuntimeException>()),
      );
    });

    test('calling shutdown twice throws RuntimeException', () async {
      await bootstrap.boot();
      await bootstrap.shutdown();
      await expectLater(
        bootstrap.shutdown(),
        throwsA(isA<RuntimeException>()),
      );
    });

    test('module onStop failure wraps in RuntimeException', () async {
      bootstrap.addModule(FailingModule(failOn: 'onStop'));
      await bootstrap.boot();
      await expectLater(
        bootstrap.shutdown(),
        throwsA(isA<RuntimeException>()),
      );
    });

    test('module onDispose failure wraps in RuntimeException', () async {
      bootstrap.addModule(FailingModule(failOn: 'onDispose'));
      await bootstrap.boot();
      // onStop on a FailingModule that only fails on onDispose will succeed
      await expectLater(
        bootstrap.shutdown(),
        throwsA(isA<RuntimeException>()),
      );
    });
  });
}
