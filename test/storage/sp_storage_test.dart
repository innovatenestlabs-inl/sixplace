import 'package:sixplace/storage.dart';
import 'package:test/test.dart';

void main() {
  test(
    'memory preference store copies string lists and enforces types',
    () async {
      final preferences = SPMemoryPreferencesStore();
      final secure = SPMemorySecureStore();
      final storage = SPStorage(preferences: preferences, secure: secure);
      final values = <String>['one'];

      await storage.writePreference('items', values);
      values.add('two');

      final stored = await storage.readPreference<List<String>>('items');
      expect(stored, ['one']);
      expect(() => stored!.add('three'), throwsUnsupportedError);

      expect(
        () => storage.writePreference('bad', <String, Object?>{'x': 1}),
        throwsArgumentError,
      );
    },
  );

  test('secure memory store supports the storage facade', () async {
    final storage = SPStorage(
      preferences: SPMemoryPreferencesStore(),
      secure: SPMemorySecureStore(),
    );

    await storage.writeSecure('token', 'secret');
    expect(await storage.containsSecure('token'), isTrue);
    expect(await storage.readSecure('token'), 'secret');

    await storage.removeSecure('token');
    expect(await storage.readSecure('token'), isNull);
  });

  test('cache is bounded, promotes reads and expires lazily', () {
    var now = DateTime.utc(2026, 9, 28, 6);
    final cache = SPStorageCache(maxEntries: 2, clock: () => now);

    cache.put('a', 1);
    cache.put('b', 2);
    expect(cache.get<int>('a'), 1);
    cache.put('c', 3);

    expect(cache.containsKey('a'), isTrue);
    expect(cache.containsKey('b'), isFalse);
    expect(cache.get<int>('c'), 3);

    cache.put('short', 'value', ttl: const Duration(seconds: 1));
    now = now.add(const Duration(seconds: 2));
    expect(cache.get<String>('short'), isNull);
  });

  test('cache reports type mismatches instead of casting silently', () {
    final cache = SPStorageCache();
    cache.put('count', 3);

    expect(() => cache.get<String>('count'), throwsStateError);
  });
}
