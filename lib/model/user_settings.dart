import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static late SharedPreferences _prefs;

  static Future<String> getAmbianceDirectory() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('ambiance_directory') ?? '';
  }

  static Future<void> setAmbianceDirectory(String dir) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setString('ambiance_directory', dir);
  }

  static Future<String> getMusicDirectory() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('music_directory') ?? '';
  }

  static Future<void> setMusicDirectory(String dir) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setString('music_directory', dir);
  }

  static Future<String> getEffectDirectory() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getString('effect_directory') ?? '';
  }

  static Future<void> setEffectDirectory(String dir) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setString('effect_directory', dir);
  }

  static Future<double> getAmbianceVolume() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getDouble('ambiance_volume') ?? 1.0;
  }

  static Future<void> setAmbianceVolume(double volume) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setDouble('ambiance_volume', volume);
  }

  static Future<double> getMusicVolume() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getDouble('music_volume') ?? 1.0;
  }

  static Future<void> setMusicVolume(double volume) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setDouble('music_volume', volume);
  }

  static Future<double> getEffectVolume() async {
    _prefs = await SharedPreferences.getInstance();
    return _prefs.getDouble('effect_volume') ?? 1.0;
  }

  static Future<void> setEffectVolume(double volume) async {
    _prefs = await SharedPreferences.getInstance();
    _prefs.setDouble('effect_volume', volume);
  }
}
