import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';
import 'package:sixplace/device_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MemoryPreferences preferences;

  setUp(() {
    if (!kIsWeb) {
      preferences = _MemoryPreferences();
      SharedPreferencesAsyncPlatform.instance = preferences;
    }
  });

  tearDown(() {
    if (!kIsWeb) SharedPreferencesAsyncPlatform.instance = null;
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'registration ID is stable, persisted and generated once concurrently',
    () async {
      final firstRequest = SPDeviceInfo.getRegistrationId();
      final secondRequest = SPDeviceInfo.getRegistrationId();
      final ids = await Future.wait([firstRequest, secondRequest]);

      expect(ids[1], ids[0]);
      expect(
        RegExp(
          r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
        ).hasMatch(ids[0]),
        isTrue,
      );
      expect(preferences.readCount, 1);
      expect(preferences.writeCount, 1);
      expect(preferences.values['sixplace.device.registration_id.v1'], ids[0]);
      expect(await SPDeviceInfo.getRegistrationId(), ids[0]);
      expect(preferences.writeCount, 1);
    },
    skip: kIsWeb,
  );

  test('registration ID reuses a valid stored value', () async {
    const storedId = '123e4567-e89b-42d3-a456-426614174000';
    preferences.values['sixplace.device.registration_id.v1'] = storedId;

    expect(await SPDeviceInfo.getRegistrationId(), storedId);
    expect(preferences.writeCount, 0);
  }, skip: kIsWeb);

  test(
    'registration ID replaces and persists an invalid stored value',
    () async {
      preferences.values['sixplace.device.registration_id.v1'] = 'not-a-uuid';

      final id = await SPDeviceInfo.getRegistrationId();

      expect(id, isNot('not-a-uuid'));
      expect(preferences.values['sixplace.device.registration_id.v1'], id);
      expect(preferences.writeCount, 1);
    },
    skip: kIsWeb,
  );

  test(
    'registration ID storage failures are surfaced and can be retried',
    () async {
      preferences.failWrites = true;

      await expectLater(SPDeviceInfo.getRegistrationId(), throwsStateError);
      expect(preferences.values, isEmpty);

      preferences.failWrites = false;
      final id = await SPDeviceInfo.getRegistrationId();

      expect(preferences.values['sixplace.device.registration_id.v1'], id);
    },
    skip: kIsWeb,
  );

  test(
    'registration ID read failures are surfaced without creating a value',
    () async {
      preferences.failReads = true;

      await expectLater(SPDeviceInfo.getRegistrationId(), throwsStateError);

      expect(preferences.values, isEmpty);
      expect(preferences.writeCount, 0);
    },
    skip: kIsWeb,
  );

  test('unavailable platform metadata remains null', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

    final info = await SPDeviceInfo.getInfo();

    expect(info.platform, 'fuchsia');
    expect(info.deviceId, isNull);
    expect(info.deviceIdSource, isNull);
    expect(info.model, isNull);
    expect(info.name, isNull);
    expect(info.batteryLevel, isNull);
    expect(info.batteryState, isNull);
  }, skip: kIsWeb);

  test('snapshot separates OS identifier and installation identifier', () {
    const snapshot = SPDeviceSnapshot(
      platform: 'android',
      deviceId: 'a4df9340dfe81234',
      deviceIdSource: 'android_id',
      installationId: 'my-app-installation-id',
      model: 'Pixel',
      name: 'Pixel Test',
      manufacturer: 'Google',
      brand: 'google',
      osName: 'android',
      osVersion: '16',
      isPhysicalDevice: true,
      localIpAddresses: ['192.168.1.42'],
      batteryLevel: 78,
      batteryState: 'charging',
      properties: {},
    );
    expect(snapshot.localIpAddress, '192.168.1.42');
    expect(snapshot.toMap()['deviceIdSource'], 'android_id');
    expect(snapshot.toMap()['installationId'], 'my-app-installation-id');
    expect(snapshot.toMap()['batteryLevel'], 78);
  });

  test('web snapshot has no fabricated OS device ID', () {
    const snapshot = SPDeviceSnapshot(
      platform: 'web',
      deviceId: null,
      deviceIdSource: null,
      installationId: 'web-installation-uuid',
      model: null,
      name: null,
      manufacturer: null,
      brand: null,
      osName: 'web',
      osVersion: null,
      isPhysicalDevice: null,
      localIpAddresses: [],
      batteryLevel: null,
      batteryState: null,
      properties: {},
    );
    expect(snapshot.deviceId, isNull);
    expect(snapshot.localIpAddress, isNull);
    expect(snapshot.installationId, 'web-installation-uuid');
  });

  test('browser registration ID persists and has no OS device ID', () async {
    final first = await SPDeviceInfo.getRegistrationId();
    final second = await SPDeviceInfo.getRegistrationId();
    final info = await SPDeviceInfo.getInfo();

    expect(second, first);
    expect(info.platform, 'web');
    expect(await SPDeviceInfo.getDeviceId(), isNull);
    expect(info.deviceId, isNull);
    expect(info.deviceIdSource, isNull);
    expect(info.installationId, first);
  }, skip: !kIsWeb);
}

base class _MemoryPreferences extends SharedPreferencesAsyncPlatform {
  final Map<String, Object> values = {};
  int readCount = 0;
  int writeCount = 0;
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> getString(
    String key,
    SharedPreferencesOptions options,
  ) async {
    readCount++;
    if (failReads) throw StateError('Preference reads are unavailable.');
    return values[key] as String?;
  }

  @override
  Future<void> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) async {
    writeCount++;
    if (failWrites) throw StateError('Preference writes are unavailable.');
    values[key] = value;
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) async =>
      values[key] as bool?;

  @override
  Future<double?> getDouble(
    String key,
    SharedPreferencesOptions options,
  ) async => values[key] as double?;

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) async =>
      values[key] as int?;

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async => values[key] as List<String>?;

  @override
  Future<void> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) async {
    values[key] = value;
  }

  @override
  Future<void> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) async {
    values[key] = value;
  }

  @override
  Future<void> setInt(
    String key,
    int value,
    SharedPreferencesOptions options,
  ) async {
    values[key] = value;
  }

  @override
  Future<void> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    values[key] = value;
  }

  @override
  Future<void> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    if (allowList == null) {
      values.clear();
    } else {
      for (final key in allowList) {
        values.remove(key);
      }
    }
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    return Map.fromEntries(
      values.entries.where(
        (entry) => allowList == null || allowList.contains(entry.key),
      ),
    );
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    final allowList = parameters.filter.allowList;
    return values.keys
        .where((key) => allowList == null || allowList.contains(key))
        .toSet();
  }
}
