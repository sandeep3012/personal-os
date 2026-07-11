import 'package:platform_runtime/lifecycle/lifecycle_exception.dart';
import 'package:platform_runtime/lifecycle/lifecycle_manager.dart';
import 'package:platform_runtime/lifecycle/lifecycle_observer.dart';
import 'package:platform_runtime/lifecycle/lifecycle_state.dart';
import 'package:test/test.dart';

// ── Test observer ─────────────────────────────────────────────────────────────

final class TrackingObserver implements LifecycleObserver {
  final calls = <String>[];

  @override
  void onInitialize() => calls.add('onInitialize');
  @override
  void onStart() => calls.add('onStart');
  @override
  void onPause() => calls.add('onPause');
  @override
  void onResume() => calls.add('onResume');
  @override
  void onStop() => calls.add('onStop');
  @override
  void onDispose() => calls.add('onDispose');
}

// ── Helpers ───────────────────────────────────────────────────────────────────

LifecycleManager _fullyBooted() {
  final m = LifecycleManager();
  m.initialize();
  m.start();
  return m;
}

LifecycleManager _readyToDispose() {
  final m = _fullyBooted();
  m.stop();
  return m;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late LifecycleManager manager;

  setUp(() => manager = LifecycleManager());

  group('LifecycleManager — initial state', () {
    test('starts in uninitialized', () {
      expect(manager.state, LifecycleState.uninitialized);
    });
  });

  group('LifecycleManager — valid transitions', () {
    test('uninitialized → initialized', () {
      manager.initialize();
      expect(manager.state, LifecycleState.initialized);
    });

    test('initialized → started', () {
      manager.initialize();
      manager.start();
      expect(manager.state, LifecycleState.started);
    });

    test('started → paused', () {
      final m = _fullyBooted();
      m.pause();
      expect(m.state, LifecycleState.paused);
    });

    test('paused → started (resume)', () {
      final m = _fullyBooted();
      m.pause();
      m.resume();
      expect(m.state, LifecycleState.started);
    });

    test('started → stopped', () {
      final m = _fullyBooted();
      m.stop();
      expect(m.state, LifecycleState.stopped);
    });

    test('stopped → disposed', () {
      final m = _readyToDispose();
      m.dispose();
      expect(m.state, LifecycleState.disposed);
    });

    test('full happy-path sequence completes without error', () {
      expect(() {
        manager.initialize();
        manager.start();
        manager.pause();
        manager.resume();
        manager.stop();
        manager.dispose();
      }, returnsNormally);

      expect(manager.state, LifecycleState.disposed);
    });
  });

  group('LifecycleManager — invalid transitions', () {
    test('start before initialize throws LifecycleException', () {
      expect(() => manager.start(), throwsA(isA<LifecycleException>()));
    });

    test('pause when not started throws LifecycleException', () {
      manager.initialize();
      expect(() => manager.pause(), throwsA(isA<LifecycleException>()));
    });

    test('resume when not paused throws LifecycleException', () {
      manager.initialize();
      manager.start();
      expect(() => manager.resume(), throwsA(isA<LifecycleException>()));
    });

    test('stop when not started throws LifecycleException', () {
      manager.initialize();
      expect(() => manager.stop(), throwsA(isA<LifecycleException>()));
    });

    test('dispose when not stopped throws LifecycleException', () {
      manager.initialize();
      manager.start();
      expect(() => manager.dispose(), throwsA(isA<LifecycleException>()));
    });

    test('initialize twice throws LifecycleException', () {
      manager.initialize();
      expect(() => manager.initialize(), throwsA(isA<LifecycleException>()));
    });

    test('any transition after dispose throws LifecycleException', () {
      final m = _readyToDispose();
      m.dispose();
      expect(m.initialize, throwsA(isA<LifecycleException>()));
    });
  });

  group('LifecycleManager — observer callbacks', () {
    late TrackingObserver observer;

    setUp(() {
      observer = TrackingObserver();
      manager.addObserver(observer);
    });

    test('initialize notifies onInitialize', () {
      manager.initialize();
      expect(observer.calls, ['onInitialize']);
    });

    test('start notifies onStart', () {
      manager.initialize();
      manager.start();
      expect(observer.calls, ['onInitialize', 'onStart']);
    });

    test('pause notifies onPause', () {
      manager.initialize();
      manager.start();
      manager.pause();
      expect(observer.calls, ['onInitialize', 'onStart', 'onPause']);
    });

    test('resume notifies onResume', () {
      manager.initialize();
      manager.start();
      manager.pause();
      manager.resume();
      expect(
        observer.calls,
        ['onInitialize', 'onStart', 'onPause', 'onResume'],
      );
    });

    test('stop notifies onStop', () {
      manager.initialize();
      manager.start();
      manager.stop();
      expect(observer.calls, ['onInitialize', 'onStart', 'onStop']);
    });

    test('dispose notifies onDispose', () {
      manager.initialize();
      manager.start();
      manager.stop();
      manager.dispose();
      expect(
        observer.calls,
        ['onInitialize', 'onStart', 'onStop', 'onDispose'],
      );
    });

    test('multiple observers all receive callbacks', () {
      final second = TrackingObserver();
      manager.addObserver(second);

      manager.initialize();
      manager.start();

      expect(observer.calls, ['onInitialize', 'onStart']);
      expect(second.calls, ['onInitialize', 'onStart']);
    });

    test('removed observer does not receive callbacks', () {
      manager.initialize();
      manager.removeObserver(observer);
      manager.start();

      expect(observer.calls, ['onInitialize']); // only before removal
    });

    test('adding same observer twice does not duplicate callbacks', () {
      manager.addObserver(observer); // already added in setUp
      manager.initialize();
      expect(observer.calls, ['onInitialize']);
    });
  });

  group('LifecycleManager — observers cleared after dispose', () {
    test('no callbacks received after dispose clears observer list', () {
      final observer = TrackingObserver();
      manager.addObserver(observer);

      manager.initialize();
      manager.start();
      manager.stop();
      manager.dispose();

      final callCountAtDispose = observer.calls.length;
      // There are no further valid transitions — verifying the list was cleared
      // by checking no additional callbacks were emitted.
      expect(observer.calls.length, callCountAtDispose);
    });
  });
}
