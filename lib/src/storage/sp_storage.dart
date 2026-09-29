import 'dart:collection';

/// Persistent preference-style key/value storage abstraction.
///
/// Implementations should support the same primitive value set commonly used by
/// preference stores: `String`, `bool`, `int`, `double` and `List<String>`.
abstract interface class SPPreferencesStore {
  /// Reads a value, or null when [key] does not exist.
  Future<Object?> read(String key);

  /// Writes a supported preference [value].
  Future<void> write(String key, Object value);

  /// Returns whether [key] exists.
  Future<bool> containsKey(String key);

  /// Removes [key] if present.
  Future<void> remove(String key);

  /// Removes every value owned by this store.
  Future<void> clear();
}

/// String-based secure-storage abstraction.
///
/// This interface intentionally does not choose a platform plugin. Applications
/// can adapt their preferred secure-storage implementation without Sixplace
/// imposing native configuration or reducing platform compatibility.
abstract interface class SPSecureStore {
  /// Reads a secret string, or null when [key] does not exist.
  Future<String?> read(String key);

  /// Writes a secret string.
  Future<void> write(String key, String value);

  /// Returns whether [key] exists.
  Future<bool> containsKey(String key);

  /// Removes [key] if present.
  Future<void> remove(String key);

  /// Removes every secret owned by this store.
  Future<void> clear();
}

/// In-memory preference store useful for tests, previews and session data.
///
/// Values are not persisted between process launches. Use a persistent adapter
/// in production when data must survive application restarts.
class SPMemoryPreferencesStore implements SPPreferencesStore {
  final Map<String, Object> _values = <String, Object>{};

  @override
  Future<Object?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, Object value) async {
    _validatePreferenceValue(value);
    _values[key] = _copyPreferenceValue(value);
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

/// In-memory implementation of [SPSecureStore] for tests and ephemeral data.
///
/// This class does not encrypt memory and must not be presented as persistent
/// secure storage. Production applications should inject an OS-backed adapter.
class SPMemorySecureStore implements SPSecureStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clear() async {
    _values.clear();
  }
}

/// Bounded in-memory cache with optional time-to-live expiration.
///
/// Expired entries are removed lazily during cache operations. No periodic
/// timer or background task is created.
class SPStorageCache {
  /// Creates a cache with an optional [maxEntries] bound.
  ///
  /// [clock] is primarily useful for deterministic tests.
  SPStorageCache({this.maxEntries = 100, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    if (maxEntries < 1) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'Must be positive.');
    }
  }

  /// Maximum number of entries retained at once.
  final int maxEntries;

  final DateTime Function() _clock;
  final LinkedHashMap<String, _SPCacheEntry> _entries =
      LinkedHashMap<String, _SPCacheEntry>();

  /// Number of currently live entries.
  int get length {
    purgeExpired();
    return _entries.length;
  }

  /// Returns whether a non-expired [key] exists.
  bool containsKey(String key) {
    purgeExpired();
    return _entries.containsKey(key);
  }

  /// Reads and promotes [key] as the most recently used cache entry.
  ///
  /// A stored value whose runtime type does not match [T] throws [StateError]
  /// rather than silently returning an incorrect value.
  T? get<T>(String key) {
    final entry = _liveEntry(key);
    if (entry == null) return null;
    final value = entry.value;
    if (value is! T) {
      throw StateError(
        'Cached value for "$key" is ${value.runtimeType}, not $T.',
      );
    }
    _entries.remove(key);
    _entries[key] = entry;
    return value;
  }

  /// Stores [value], optionally expiring it after [ttl].
  void put<T>(String key, T value, {Duration? ttl}) {
    if (ttl != null && ttl <= Duration.zero) {
      throw ArgumentError.value(ttl, 'ttl', 'Must be positive.');
    }
    final expiresAt = ttl == null ? null : _clock().add(ttl);
    _entries.remove(key);
    _entries[key] = _SPCacheEntry(value, expiresAt);
    purgeExpired();
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes [key] and returns whether it existed.
  bool remove(String key) => _entries.remove(key) != null;

  /// Removes all cached values.
  void clear() => _entries.clear();

  /// Removes expired values and returns the number removed.
  int purgeExpired() {
    final now = _clock();
    final expired = <String>[];
    for (final entry in _entries.entries) {
      final expiry = entry.value.expiresAt;
      if (expiry != null && !expiry.isAfter(now)) {
        expired.add(entry.key);
      }
    }
    for (final key in expired) {
      _entries.remove(key);
    }
    return expired.length;
  }

  _SPCacheEntry? _liveEntry(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    final expiry = entry.expiresAt;
    if (expiry != null && !expiry.isAfter(_clock())) {
      _entries.remove(key);
      return null;
    }
    return entry;
  }
}

/// Coordinates preference, secure and in-memory cache providers.
///
/// Sixplace owns no platform persistence plugin. This facade keeps application
/// code stable while allowing the consuming app to inject platform-appropriate
/// implementations for [SPPreferencesStore] and [SPSecureStore].
class SPStorage {
  /// Creates a storage facade.
  SPStorage({
    required this.preferences,
    required this.secure,
    SPStorageCache? cache,
  }) : cache = cache ?? SPStorageCache();

  /// Preference-style persistent provider.
  final SPPreferencesStore preferences;

  /// Secret string provider.
  final SPSecureStore secure;

  /// Process-memory cache.
  final SPStorageCache cache;

  /// Reads a typed preference value.
  Future<T?> readPreference<T>(String key) async {
    final value = await preferences.read(key);
    if (value == null) return null;
    if (value is! T) {
      throw StateError('Preference "$key" is ${value.runtimeType}, not $T.');
    }
    return _copyPreferenceValue(value) as T;
  }

  /// Writes a supported preference value.
  Future<void> writePreference(String key, Object value) {
    _validatePreferenceValue(value);
    return preferences.write(key, _copyPreferenceValue(value));
  }

  /// Returns whether a preference exists.
  Future<bool> containsPreference(String key) => preferences.containsKey(key);

  /// Removes a preference value.
  Future<void> removePreference(String key) => preferences.remove(key);

  /// Clears all values owned by the preference provider.
  Future<void> clearPreferences() => preferences.clear();

  /// Reads a secure string.
  Future<String?> readSecure(String key) => secure.read(key);

  /// Writes a secure string.
  Future<void> writeSecure(String key, String value) =>
      secure.write(key, value);

  /// Returns whether a secure value exists.
  Future<bool> containsSecure(String key) => secure.containsKey(key);

  /// Removes a secure value.
  Future<void> removeSecure(String key) => secure.remove(key);

  /// Clears all values owned by the secure provider.
  Future<void> clearSecure() => secure.clear();
}

class _SPCacheEntry {
  const _SPCacheEntry(this.value, this.expiresAt);

  final Object? value;
  final DateTime? expiresAt;
}

void _validatePreferenceValue(Object value) {
  if (value is String || value is bool || value is int || value is double) {
    return;
  }
  if (value is List<String>) return;
  throw ArgumentError.value(
    value,
    'value',
    'Preferences support String, bool, int, double and List<String>.',
  );
}

Object _copyPreferenceValue(Object value) =>
    value is List<String> ? List<String>.unmodifiable(value) : value;
