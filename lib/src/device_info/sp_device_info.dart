import 'package:android_id/android_id.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import 'sp_local_ip.dart';

/// Information made available by the OS, not a hardware fingerprint.
///
/// [deviceId] is Android ANDROID_ID, iOS identifierForVendor, or null where
/// no comparable identifier exists. It is NOT an IMEI, serial number or a
/// globally unique/permanent physical-device identifier.
@immutable
class SPDeviceSnapshot {
  const SPDeviceSnapshot({
    required this.platform,
    required this.deviceId,
    required this.deviceIdSource,
    this.installationId,
    required this.model,
    required this.name,
    required this.manufacturer,
    required this.brand,
    required this.osName,
    required this.osVersion,
    required this.isPhysicalDevice,
    required this.localIpAddresses,
    required this.batteryLevel,
    required this.batteryState,
    required this.properties,
  });

  final String platform;
  final String? deviceId;
  final String? deviceIdSource;
  final String? installationId;
  String? get bestAvailableId => deviceId ?? installationId;
  final String? model;
  final String? name;
  final String? manufacturer;
  final String? brand;
  final String? osName;
  final String? osVersion;
  final bool? isPhysicalDevice;
  /// Locally assigned IPs, not the internet-facing public address.
  final List<String> localIpAddresses;
  /// Battery percentage from 0 to 100; null if not available.
  final int? batteryLevel;
  /// e.g. charging, discharging, full, unknown; null if unavailable.
  final String? batteryState;
  /// Additional OS-provided metadata. Do not transmit without user consent.
  final Map<String, Object?> properties;

  String? get localIpAddress =>
      localIpAddresses.isEmpty ? null : localIpAddresses.first;

  Map<String, Object?> toMap() => {
    'platform': platform,
    'deviceId': deviceId,
    'deviceIdSource': deviceIdSource,
    'installationId': installationId,
    'bestAvailableId': bestAvailableId,
    'model': model,
    'name': name,
    'manufacturer': manufacturer,
    'brand': brand,
    'osName': osName,
    'osVersion': osVersion,
    'isPhysicalDevice': isPhysicalDevice,
    'localIpAddresses': localIpAddresses,
    'batteryLevel': batteryLevel,
    'batteryState': batteryState,
    'properties': properties,
  };
}

/// A cross-platform, permission-free helper. No manifest/Info.plist edits.
///
/// No login or initialization is required. OS fields and battery state are
/// read live on each call. Prefer using a snapshot per screen refresh rather
/// than polling every frame. Unsupported/unavailable values are null.
///
/// On Android 8+, ANDROID_ID is scoped to app signing key + OS user + device;
/// a factory reset or signing-key change can alter it. On Apple devices,
/// identifierForVendor may change when all apps from the vendor are removed.
/// Neither should serve as an authentication secret or sole anti-fraud key.
class SPDeviceInfo {
  SPDeviceInfo._();

  static final DeviceInfoPlugin _device = DeviceInfoPlugin();
  static final Battery _battery = Battery();

  static Future<String?> getDeviceId() async {
    if (kIsWeb) return null;
    try {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return const AndroidId().getId();
        case TargetPlatform.iOS:
          return (await _device.iosInfo).identifierForVendor;
        case TargetPlatform.windows:
          return (await _device.windowsInfo).deviceId;
        case TargetPlatform.macOS:
          return (await _device.macOsInfo).systemGUID;
        case TargetPlatform.linux:
          return (await _device.linuxInfo).machineId;
        case TargetPlatform.fuchsia:
          return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level >= 0 && level <= 100 ? level : null;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getBatteryState() async {
    try {
      return (await _battery.batteryState).name;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> getLocalIpAddresses() async {
    if (kIsWeb) return const [];
    try {
      return await spLocalIpAddresses();
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> getLocalIpAddress() async {
    final addresses = await getLocalIpAddresses();
    return addresses.isEmpty ? null : addresses.first;
  }

  static Future<SPDeviceSnapshot> getInfo() async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    Map<String, dynamic> data;
    try {
      data = (await _device.deviceInfo).data;
    } catch (_) {
      data = {};
    }

    String? read(String key) {
      final value = data[key];
      if (value == null) return null;
      final result = value.toString().trim();
      return result.isEmpty || result == 'null' ? null : result;
    }

    // Platform-specific device_info_plus properties have different names.
    final model = read('model') ?? read('machine');
    final name = read('name') ?? read('computerName') ?? read('hostName');
    final version = data['version'];
    final osVersion = version is Map
        ? version['release']?.toString()
        : read('systemVersion') ?? read('osRelease') ?? read('osVersion');
    final deviceId = await getDeviceId();
    final results = await Future.wait<Object?>([
      getLocalIpAddresses(),
      getBatteryLevel(),
      getBatteryState(),
    ]);
    return SPDeviceSnapshot(
      platform: platform,
      deviceId: deviceId,
      deviceIdSource: deviceId == null ? null :
          platform == 'android' ? 'android_id' : platform == 'iOS' ? 'identifier_for_vendor' : platform == 'windows' ? 'windows_device_id' : platform == 'macOS' ? 'macos_system_guid' : platform == 'linux' ? 'linux_machine_id' : null,
      model: model,
      name: name,
      manufacturer: read('manufacturer'),
      brand: read('brand'),
      osName: read('systemName') ?? platform,
      osVersion: osVersion,
      isPhysicalDevice: data['isPhysicalDevice'] is bool
          ? data['isPhysicalDevice'] as bool : null,
      localIpAddresses: List<String>.unmodifiable(results[0] as List<String>),
      batteryLevel: results[1] as int?,
      batteryState: results[2] as String?,
      properties: Map<String, Object?>.unmodifiable(
        data.map((key, value) => MapEntry(key, value as Object?)),
      ),
    );
  }
}
