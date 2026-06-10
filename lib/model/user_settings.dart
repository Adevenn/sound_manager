import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_manager/model.dart';

/// Per-channel user preferences (source directory, volume, current playlist and
/// last-played track), **scoped to the active campaign**.
///
/// Key scheme: for the Default campaign the legacy unprefixed key is used
/// (e.g. `ambiance_volume`), so existing installs and the legacy tests keep
/// working untouched. Other campaigns get a `camp_<campaign>_` prefix so each
/// campaign remembers its own per-channel state.
///
/// Backed by the shared [Prefs] instance, so all accessors are synchronous;
/// [Prefs.init] must have run first.
class UserSettings {
  UserSettings._();

  static SharedPreferences get _prefs => Prefs.instance;

  /// Builds the storage key for [suffix], namespacing by the active campaign
  /// (Default keeps the legacy unprefixed key).
  static String _key(String suffix) {
    final campaign = CampaignManager.instance.current.value;
    if (campaign == CampaignManager.defaultCampaign) return suffix;
    return 'camp_${campaign}_$suffix';
  }

  static String? getPlayerSourceDirectory(PlayerType type) =>
      _prefs.getString(_key('${type.name}_source_directory'));

  static Future<void> setPlayerSourceDirectory(
    PlayerType type,
    String dirPath,
  ) => _prefs.setString(_key('${type.name}_source_directory'), dirPath);

  static double getPlayerVolume(PlayerType type) =>
      _prefs.getDouble(_key('${type.name}_volume')) ?? 1.0;

  static Future<void> setPlayerVolume(PlayerType type, double volume) =>
      _prefs.setDouble(_key('${type.name}_volume'), volume);

  /// Name of the playlist last loaded on [type] (empty string when none).
  /// Playlists are stored on disk as `<name>.json`, so we persist the name (not
  /// the id) to be able to reload it with `PlaylistRepository.load`.
  static String getCurrentPlaylist(PlayerType type) =>
      _prefs.getString(_key('${type.name}_current_playlist')) ?? '';

  /// Persists [name] as the channel's current playlist. When it actually
  /// switches to a *different* playlist, the resume position is reset to 0 so
  /// the new playlist doesn't start at an index inherited from the old one.
  static Future<void> setCurrentPlaylist(PlayerType type, String name) async {
    final changed = getCurrentPlaylist(type) != name;
    await _prefs.setString(_key('${type.name}_current_playlist'), name);
    if (changed) await setTrackIndex(type, 0);
  }

  /// Index of the track that was selected on [type] when the app last closed,
  /// so playback resumes on the same track.
  static int getTrackIndex(PlayerType type) =>
      _prefs.getInt(_key('${type.name}_track_index')) ?? 0;

  static Future<void> setTrackIndex(PlayerType type, int index) =>
      _prefs.setInt(_key('${type.name}_track_index'), index);
}
