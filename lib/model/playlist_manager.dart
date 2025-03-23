import '../model.dart';

class PlaylistManager {
  late Playlist playlist;
  late final AudioPlayerManager player;

  PlaylistManager({required PlayerType type}) {
    player = AudioPlayerManager(type, nextTrack);
  }

  void get pause => player.pause();

  void previousTrack() {
    player.changeTrack(playlist.previousSoundtrack);
    playlist.previousTrack();
  }

  void nextTrack() {
    player.changeTrack(playlist.nextSoundtrack);
    playlist.nextTrack();
  }

  void loadPlaylistInPlayer() {
    player.changeTrack(playlist.actualSoundtrack);
  }

  void dispose() {
    player.dispose();
  }

  Future<void> loadSettings() async {
    await player.loadSettings();
    final currentPlaylist = await UserSettings.getCurrentPlaylist(player.type);
    playlist =
        currentPlaylist != ''
            ? Playlist.fromFile(currentPlaylist)
            : Playlist.empty('Custom');
  }
}
