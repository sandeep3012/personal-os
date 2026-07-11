import 'package:platform_core/result/result.dart';
import 'package:platform_storage/preferences/i_preferences.dart';
import 'package:test/test.dart';

// ── In-memory fake ────────────────────────────────────────────────────────────

final class InMemoryPreferences implements IPreferences {
  final _store = <String, Object>{};

  Result<T> _ok<T>(T value) => Result.success(value);

  @override
  Future<Result<String?>> getString(String key) async =>
      _ok(_store[key] as String?);

  @override
  Future<Result<int?>> getInt(String key) async =>
      _ok(_store[key] as int?);

  @override
  Future<Result<double?>> getDouble(String key) async =>
      _ok(_store[key] as double?);

  @override
  Future<Result<bool?>> getBool(String key) async =>
      _ok(_store[key] as bool?);

  @override
  Future<Result<List<String>?>> getStringList(String key) async =>
      _ok(_store[key] as List<String>?);

  @override
  Future<Result<void>> setString(String key, String value) async {
    _store[key] = value;
    return _ok(null);
  }

  @override
  Future<Result<void>> setInt(String key, int value) async {
    _store[key] = value;
    return _ok(null);
  }

  @override
  Future<Result<void>> setDouble(String key, double value) async {
    _store[key] = value;
    return _ok(null);
  }

  @override
  Future<Result<void>> setBool(String key, bool value) async {
    _store[key] = value;
    return _ok(null);
  }

  @override
  Future<Result<void>> setStringList(String key, List<String> value) async {
    _store[key] = value;
    return _ok(null);
  }

  @override
  Future<Result<void>> remove(String key) async {
    _store.remove(key);
    return _ok(null);
  }

  @override
  Future<Result<void>> clear() async {
    _store.clear();
    return _ok(null);
  }

  @override
  Future<Result<bool>> containsKey(String key) async =>
      _ok(_store.containsKey(key));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late InMemoryPreferences prefs;

  setUp(() => prefs = InMemoryPreferences());

  group('IPreferences — String', () {
    test('getString returns null before set', () async {
      final r = await prefs.getString('key');
      expect(r.valueOrNull, isNull);
    });

    test('setString then getString returns value', () async {
      await prefs.setString('greeting', 'hello');
      final r = await prefs.getString('greeting');
      expect(r.valueOrNull, 'hello');
    });
  });

  group('IPreferences — int', () {
    test('getInt returns null before set', () async {
      expect((await prefs.getInt('x')).valueOrNull, isNull);
    });

    test('setInt then getInt returns value', () async {
      await prefs.setInt('count', 42);
      expect((await prefs.getInt('count')).valueOrNull, 42);
    });
  });

  group('IPreferences — double', () {
    test('getDouble returns null before set', () async {
      expect((await prefs.getDouble('pi')).valueOrNull, isNull);
    });

    test('setDouble then getDouble returns value', () async {
      await prefs.setDouble('pi', 3.14);
      expect((await prefs.getDouble('pi')).valueOrNull, closeTo(3.14, 0.001));
    });
  });

  group('IPreferences — bool', () {
    test('getBool returns null before set', () async {
      expect((await prefs.getBool('flag')).valueOrNull, isNull);
    });

    test('setBool true then getBool returns true', () async {
      await prefs.setBool('flag', true);
      expect((await prefs.getBool('flag')).valueOrNull, isTrue);
    });

    test('setBool false then getBool returns false', () async {
      await prefs.setBool('flag', false);
      expect((await prefs.getBool('flag')).valueOrNull, isFalse);
    });
  });

  group('IPreferences — List<String>', () {
    test('getStringList returns null before set', () async {
      expect((await prefs.getStringList('list')).valueOrNull, isNull);
    });

    test('setStringList then getStringList returns value', () async {
      await prefs.setStringList('tags', ['a', 'b', 'c']);
      expect(
        (await prefs.getStringList('tags')).valueOrNull,
        ['a', 'b', 'c'],
      );
    });
  });

  group('IPreferences — remove', () {
    test('remove deletes the key', () async {
      await prefs.setString('k', 'v');
      await prefs.remove('k');
      expect((await prefs.getString('k')).valueOrNull, isNull);
    });

    test('remove of non-existent key returns success', () async {
      final r = await prefs.remove('nonexistent');
      expect(r.isSuccess, isTrue);
    });
  });

  group('IPreferences — clear', () {
    test('clear removes all keys', () async {
      await prefs.setString('a', '1');
      await prefs.setInt('b', 2);
      await prefs.clear();
      expect((await prefs.getString('a')).valueOrNull, isNull);
      expect((await prefs.getInt('b')).valueOrNull, isNull);
    });
  });

  group('IPreferences — containsKey', () {
    test('returns false for missing key', () async {
      expect((await prefs.containsKey('missing')).valueOrNull, isFalse);
    });

    test('returns true after set', () async {
      await prefs.setString('present', 'yes');
      expect((await prefs.containsKey('present')).valueOrNull, isTrue);
    });

    test('returns false after remove', () async {
      await prefs.setString('k', 'v');
      await prefs.remove('k');
      expect((await prefs.containsKey('k')).valueOrNull, isFalse);
    });
  });
}
