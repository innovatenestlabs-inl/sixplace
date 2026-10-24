import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// A stable app/browser-installation identity, not a hardware identifier.
///
/// The same stored UUID is returned across application restarts as long as
/// this app's preferences remain intact. On web storage is scoped by origin
/// and browser profile. Reinstallation, clearing browser/app data, private
/// sessions or storage restrictions can reset it.
///
/// Use this identifier for device-registration records, not authentication.
class SPInstallationIdentity {
  SPInstallationIdentity._();

  static const storageKey = 'sixplace.device.registration_id.v1';
  static Future<String>? _pending;

  /// Recommended registration identifier on every Flutter platform.
  ///
  /// Throws if storage cannot persist the value. Never silently generates
  /// a disposable identifier because that would break registered devices.
  static Future<String> getRegistrationId() =>
      _pending ??= _readOrCreate().catchError((Object error, StackTrace stack) {
        _pending = null;
        Error.throwWithStackTrace(error, stack);
      });

  static Future<String> _readOrCreate() async {
    final preferences = SharedPreferencesAsync();
    final previous = await preferences.getString(storageKey);
    if (previous != null && Uuid.isValidUUID(fromString: previous)) {
      return previous;
    }
    final newId = const Uuid().v4();
    await preferences.setString(storageKey, newId);
    return newId;
  }
}
