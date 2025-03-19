import 'package:sound_manager/model/playlist.dart';

import '../model.dart';

class PlaylistManager {
  final Playlist playlist;
  final player = AudioPlayerManager('');

  PlaylistManager(String name) : playlist = Playlist(name);
}
