import 'package:application/application.dart';
import 'package:test/test.dart';

const _home = RouteDefinition(path: '/', name: 'home');
const _dashboard = RouteDefinition(path: '/dashboard', name: 'dashboard');

RouteRegistry _registryWith(List<RouteDefinition> routes) {
  final registry = RouteRegistry();
  for (final r in routes) {
    registry.register(r);
  }
  return registry;
}

void main() {
  group('ApplicationRouter', () {
    late ApplicationRouter router;

    setUp(() {
      final registry = _registryWith([_home, _dashboard]);
      router = ApplicationRouter(registry: registry);
    });

    // ── resolveByPath ──────────────────────────────────────────────────────

    test('resolveByPath returns registered route', () {
      expect(router.resolveByPath('/'), equals(_home));
    });

    test('resolveByPath returns correct route for path', () {
      expect(router.resolveByPath('/dashboard'), equals(_dashboard));
    });

    test('resolveByPath throws NavigationException for unknown path', () {
      expect(
        () => router.resolveByPath('/unknown'),
        throwsA(isA<NavigationException>()),
      );
    });

    test('NavigationException carries the route path', () {
      try {
        router.resolveByPath('/missing');
        fail('expected NavigationException');
      } on NavigationException catch (e) {
        expect(e.route, '/missing');
      }
    });

    // ── resolveByName ──────────────────────────────────────────────────────

    test('resolveByName returns registered route', () {
      expect(router.resolveByName('home'), equals(_home));
    });

    test('resolveByName throws NavigationException for unknown name', () {
      expect(
        () => router.resolveByName('nonexistent'),
        throwsA(isA<NavigationException>()),
      );
    });

    // ── canResolve ─────────────────────────────────────────────────────────

    test('canResolveByPath returns true for known path', () {
      expect(router.canResolveByPath('/'), isTrue);
    });

    test('canResolveByPath returns false for unknown path', () {
      expect(router.canResolveByPath('/nope'), isFalse);
    });

    test('canResolveByName returns true for known name', () {
      expect(router.canResolveByName('dashboard'), isTrue);
    });

    test('canResolveByName returns false for unknown name', () {
      expect(router.canResolveByName('nope'), isFalse);
    });

    // ── empty registry ─────────────────────────────────────────────────────

    test('resolveByPath on empty registry throws NavigationException', () {
      final emptyRouter = ApplicationRouter(registry: RouteRegistry());
      expect(
        () => emptyRouter.resolveByPath('/'),
        throwsA(isA<NavigationException>()),
      );
    });
  });
}
