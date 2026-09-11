import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable id for the device-local account, stored via shared_preferences
/// (NSUserDefaults on iOS, SharedPreferences on Android) on purpose: both
/// backends are wiped on uninstall, which is what makes an uninstall/
/// reinstall restart progress from zero for players who never connected an
/// account, per 01-setup-projet-et-architecture.md.
///
/// Android note: SharedPreferences can survive an uninstall via Android's
/// automatic cloud backup unless explicitly excluded. This needs a backup
/// rule (`android:allowBackup` / `dataExtractionRules`) once the Android
/// platform project is generated (see mobile/README.md), so uninstall
/// behavior matches iOS exactly.
class DeviceIdentity {
  DeviceIdentity._();

  static const String _key = 'coffeebreak.deviceId';

  static Future<String> current() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;

    final generated = const Uuid().v4();
    await prefs.setString(_key, generated);
    return generated;
  }
}
