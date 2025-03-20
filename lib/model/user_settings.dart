import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_manager/model.dart';

class UserSettings {
  static late SharedPreferences _prefs;

  static Future<String?> getPlayerSourceDirectory(PlayerType type) async {
    _prefs = await SharedPreferences.getInstance();
    return switch (type) {
      PlayerType.ambiance => _prefs.getString('ambiance_source_directory'),
      PlayerType.music => _prefs.getString('music_source_directory'),
      PlayerType.effect => _prefs.getString('effect_source_directory'),
    };
  }

  static Future<void> setPlayerSourceDirectory(
    PlayerType type,
    String dirPath,
  ) async {
    _prefs = await SharedPreferences.getInstance();
    switch (type) {
      case PlayerType.ambiance:
        _prefs.setString('ambiance_source_directory', dirPath);
      case PlayerType.music:
        _prefs.setString('music_source_directory', dirPath);
      case PlayerType.effect:
        _prefs.setString('effect_source_directory', dirPath);
    }
  }

  static Future<double> getPlayerVolume(PlayerType type) async {
    _prefs = await SharedPreferences.getInstance();
    return switch (type) {
      PlayerType.ambiance => _prefs.getDouble('ambiance_volume') ?? 1.0,
      PlayerType.music => _prefs.getDouble('music_volume') ?? 1.0,
      PlayerType.effect => _prefs.getDouble('effect_volume') ?? 1.0,
    };
  }

  static Future<void> setPlayerVolume(PlayerType type, double volume) async {
    _prefs = await SharedPreferences.getInstance();
    switch (type) {
      case PlayerType.ambiance:
        _prefs.setDouble('ambiance_volume', volume);
      case PlayerType.music:
        _prefs.setDouble('music_volume', volume);
      case PlayerType.effect:
        _prefs.setDouble('effect_volume', volume);
    }
  }

  static Future<String?> getCurrentPlayerPlaylist(PlayerType type) async {
    _prefs = await SharedPreferences.getInstance();
    return switch (type) {
      PlayerType.ambiance => _prefs.getString('ambiance_current_playlist'),
      PlayerType.music => _prefs.getString('music_current_playlist'),
      PlayerType.effect => _prefs.getString('effect_current_playlist'),
    };
  }

  static Future<void> setCurrentPlayerPlaylist(
    PlayerType type,
    String path,
  ) async {
    _prefs = await SharedPreferences.getInstance();
    switch (type) {
      case PlayerType.ambiance:
        _prefs.setString('ambiance_current_playlist', path);
      case PlayerType.music:
        _prefs.setString('music_current_playlist', path);
      case PlayerType.effect:
        _prefs.setString('effect_current_playlist', path);
    }
  }
}
