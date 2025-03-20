import 'package:sound_manager/model/playlist.dart';

import '../model.dart';

class PlaylistManager {
  late Playlist playlist;
  final AudioPlayerManager player;

  PlaylistManager({required PlayerType type})
    : player = AudioPlayerManager(type);

  void get pause => player.pause();

  void dispose() {
    player.dispose();
  }

  Future<void> loadSettings() async {
    await player.loadSettings();
    playlist = Playlist(
      await UserSettings.getCurrentPlayerPlaylist(player.type) ?? 'Custom',
    );
  }
}
