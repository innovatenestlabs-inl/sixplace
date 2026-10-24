import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixplace/device_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration ID is stable and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await SPDeviceInfo.getRegistrationId();
    final second = await SPDeviceInfo.getRegistrationId();
    expect(first, second);
    expect(RegExp(r'^[a-f0-9-]{36}$').hasMatch(first), isTrue);
    expect(
      await SharedPreferencesAsync().getString(
        'sixplace.device.registration_id.v1',
      ),
      first,
    );
  });

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
}
