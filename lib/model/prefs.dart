import 'package:shared_preferences/shared_preferences.dart';

/// Single, eagerly-loaded [SharedPreferences] instance shared by every settings
/// class. Call [init] once at startup (before `runApp`) so the rest of the app
/// can read/write preferences synchronously instead of awaiting
/// `SharedPreferences.getInstance()` on every access.
class Prefs {
  Prefs._();

  // Not `final`: tests reset it via SharedPreferences mock + re-init.
  static late SharedPreferences instance;

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
  }
}
