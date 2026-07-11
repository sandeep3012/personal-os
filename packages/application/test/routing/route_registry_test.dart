import 'package:application/application.dart';
import 'package:test/test.dart';

const _home = RouteDefinition(path: '/', name: 'home');
const _dashboard = RouteDefinition(path: '/dashboard', name: 'dashboard');
const _settings = RouteDefinition(path: '/settings', name: 'settings');

void main() {
  group('RouteRegistry', () {
    late RouteRegistry registry;

    setUp(() => registry = RouteRegistry());

    test('is empty initially', () {
      expect(registry.isEmpty, isTrue);
      expect(registry.length, 0);
      expect(registry.routes, isEmpty);
    });

    test('register adds a route', () {
      registry.register(_home);
      expect(registry.length, 1);
      expect(registry.isNotEmpty, isTrue);
    });

    test('findByPath returns registered route', () {
      registry.register(_home);
      expect(registry.findByPath('/'), equals(_home));
    });

    test('findByName returns registered route', () {
      registry.register(_home);
      expect(registry.findByName('home'), equals(_home));
    });

    test('findByPath returns null for unknown path', () {
      expect(registry.findByPath('/unknown'), isNull);
    });

    test('findByName returns null for unknown name', () {
      expect(registry.findByName('unknown'), isNull);
    });

    test('containsPath returns true for registered path', () {
      registry.register(_home);
      expect(registry.containsPath('/'), isTrue);
    });

    test('containsPath returns false for unregistered path', () {
      expect(registry.containsPath('/nope'), isFalse);
    });

    test('containsName returns true for registered name', () {
      registry.register(_home);
      expect(registry.containsName('home'), isTrue);
    });

    test('containsName returns false for unregistered name', () {
      expect(registry.containsName('nope'), isFalse);
    });

    test('register multiple routes', () {
      registry
        ..register(_home)
        ..register(_dashboard)
        ..register(_settings);
      expect(registry.length, 3);
    });

    test('duplicate path throws ArgumentError', () {
      registry.register(_home);
      expect(
        () => registry.register(const RouteDefinition(path: '/', name: 'root')),
        throwsArgumentError,
      );
    });

    test('duplicate name throws ArgumentError', () {
      registry.register(_home);
      expect(
        () => registry.register(const RouteDefinition(path: '/home2', name: 'home')),
        throwsArgumentError,
      );
    });

    test('routes returns unmodifiable list', () {
      registry.register(_home);
      expect(
        () => registry.routes.add(_dashboard),
        throwsA(anything),
      );
    });
  });

  group('RouteDefinition', () {
    test('equality holds for same path and name', () {
      expect(
        const RouteDefinition(path: '/a', name: 'a'),
        equals(const RouteDefinition(path: '/a', name: 'a')),
      );
    });

    test('inequality when path differs', () {
      expect(
        const RouteDefinition(path: '/a', name: 'x'),
        isNot(equals(const RouteDefinition(path: '/b', name: 'x'))),
      );
    });

    test('toString includes path and name', () {
      const route = RouteDefinition(path: '/test', name: 'test');
      expect(route.toString(), contains('/test'));
      expect(route.toString(), contains('test'));
    });
  });
}
