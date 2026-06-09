import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/theme/app_theme.dart';
import 'package:sound_manager/view/playlist_screen.dart';

class PlaylistButtonWidget extends StatelessWidget {
  final Function callback;
  final AudioPlayerManager player;
  Playlist get playlist => player.playlist;

  const PlaylistButtonWidget({
    super.key,
    required this.player,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    heroTag: null,
    tooltip: 'Playlist',
    backgroundColor: player.type.style.color,
    foregroundColor: contrastOn(player.type.style.color),
    onPressed: () async {
      var newPlaylist = await showDialog<Playlist>(
        context: context,
        builder:
            (context) =>
                Dialog.fullscreen(child: PlaylistScreen(player: player)),
      );
      if (newPlaylist != null && !playlist.compare(newPlaylist)) {
        player.playlist = newPlaylist;
        // Effects are triggered individually from the soundboard, so don't
        // auto-play the first track on the main player for that channel.
        if (player.type != PlayerType.effect) {
          player.changeTrack(newPlaylist.actualSoundtrack);
        }
      }
      callback();
    },
    child: Image.asset(
      'assets/song_list.png',
      height: 24,
      width: 24,
      color: contrastOn(player.type.style.color),
      filterQuality: FilterQuality.medium,
    ),
  );
}
