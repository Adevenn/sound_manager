import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_manager/model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
  });

  group('UserSettings', () {
    test('volume defaults to 1.0 and round-trips per channel', () async {
      expect(UserSettings.getPlayerVolume(PlayerType.music), 1.0);
      await UserSettings.setPlayerVolume(PlayerType.music, 0.3);
      await UserSettings.setPlayerVolume(PlayerType.ambiance, 0.7);
      expect(UserSettings.getPlayerVolume(PlayerType.music), 0.3);
      expect(UserSettings.getPlayerVolume(PlayerType.ambiance), 0.7);
      // Channels are independent.
      expect(UserSettings.getPlayerVolume(PlayerType.effect), 1.0);
    });

    test('current playlist defaults to empty and round-trips', () async {
      expect(UserSettings.getCurrentPlaylist(PlayerType.music), '');
      await UserSettings.setCurrentPlaylist(PlayerType.music, 'Tavern');
      expect(UserSettings.getCurrentPlaylist(PlayerType.music), 'Tavern');
    });

    test('track index defaults to 0 and round-trips', () async {
      expect(UserSettings.getTrackIndex(PlayerType.ambiance), 0);
      await UserSettings.setTrackIndex(PlayerType.ambiance, 5);
      expect(UserSettings.getTrackIndex(PlayerType.ambiance), 5);
    });

    test('switching to a different playlist resets the resume index', () async {
      await UserSettings.setCurrentPlaylist(PlayerType.music, 'Tavern');
      await UserSettings.setTrackIndex(PlayerType.music, 4);
      // Same name again: position is kept (e.g. a re-save).
      await UserSettings.setCurrentPlaylist(PlayerType.music, 'Tavern');
      expect(UserSettings.getTrackIndex(PlayerType.music), 4);
      // Different name: position resets so the new playlist starts at 0.
      await UserSettings.setCurrentPlaylist(PlayerType.music, 'Battle');
      expect(UserSettings.getTrackIndex(PlayerType.music), 0);
    });

    test('reads keys written under the legacy "<channel>_..." names', () async {
      // Confirms the key scheme stayed backward-compatible after the refactor.
      SharedPreferences.setMockInitialValues({'music_volume': 0.42});
      await Prefs.init();
      expect(UserSettings.getPlayerVolume(PlayerType.music), 0.42);
    });
  });
}
