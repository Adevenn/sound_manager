import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/track_list_screen.dart';
import 'package:path/path.dart' as p;

class AudioPlayerScreen extends StatefulWidget {
  final PlaylistManager manager;
  const AudioPlayerScreen({required this.manager, super.key});

  @override
  State<StatefulWidget> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  PlaylistManager get manager => widget.manager;
  AudioPlayerManager get player => widget.manager.player;
  Playlist get playlist => widget.manager.playlist;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: widget.manager.loadSettings(),
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData ||
          snapshot.connectionState == ConnectionState.done) {
        return Row(
          spacing: 16,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width / 3.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        player.type.name.capitalize(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          var newPlaylist = await showDialog<Playlist>(
                            context: context,
                            builder:
                                (context) => Dialog.fullscreen(
                                  child: TrackListScreen(manager: manager),
                                ),
                          );
                          if (newPlaylist != null &&
                              !playlist.compare(newPlaylist)) {
                            manager.playlist = newPlaylist;
                            manager.loadPlaylistInPlayer();
                            setState(() {});
                          }
                        },
                        child: Image.asset(
                          'assets/song_list.png',
                          height: 24,
                          width: 24,
                          color: Colors.white60,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ],
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: player.path,
                    builder:
                        (BuildContext context, String? path, Widget? child) =>
                            Flexible(
                              child: (Chip(
                                label: Text(
                                  playlist.actualSoundtrack != null
                                      ? p.basenameWithoutExtension(
                                        playlist.actualSoundtrack!.source,
                                      )
                                      : "No track",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              )),
                            ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: playlist.trackIndex,
                builder:
                    (
                      BuildContext context,
                      int index,
                      Widget? child,
                    ) => ValueListenableBuilder<PlayerState>(
                      valueListenable: player.state,
                      builder:
                          (
                            BuildContext context,
                            PlayerState state,
                            Widget? child,
                          ) => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.skip_previous_rounded,
                                      size: 40,
                                    ),
                                    onPressed:
                                        playlist.isPreviousTrack
                                            ? () => manager.previousTrack()
                                            : null,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      playlist.isTracksNotEmpty
                                          ? player.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded
                                          : Icons.play_disabled_rounded,
                                      size: 40,
                                    ),
                                    onPressed:
                                        playlist.actualSoundtrack != null
                                            ? () async =>
                                                player.isPlaying
                                                    ? await player.pause()
                                                    : await player.play()
                                            : null,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.skip_next_rounded,
                                      size: 40,
                                    ),
                                    onPressed:
                                        playlist.isNextTrack
                                            ? () => manager.nextTrack()
                                            : null,
                                  ),
                                ],
                              ),
                              ValueListenableBuilder<Duration>(
                                valueListenable: player.duration,
                                builder:
                                    (
                                      BuildContext context,
                                      Duration duration,
                                      Widget? child,
                                    ) => ValueListenableBuilder<Duration>(
                                      valueListenable: player.position,
                                      builder:
                                          (
                                            BuildContext context,
                                            Duration position,
                                            Widget? child,
                                          ) => Row(
                                            children: [
                                              Text(
                                                position
                                                    .toString()
                                                    .split('.')
                                                    .first,
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                              Expanded(
                                                child: Slider(
                                                  onChanged: (value) {
                                                    final position =
                                                        value *
                                                        duration.inMilliseconds;
                                                    player.seek(position);
                                                  },
                                                  value:
                                                      (position.inMilliseconds >
                                                                  0 &&
                                                              position.inMilliseconds <
                                                                  duration
                                                                      .inMilliseconds)
                                                          ? position
                                                                  .inMilliseconds /
                                                              duration
                                                                  .inMilliseconds
                                                          : 0.0,
                                                ),
                                              ),
                                              Text(
                                                duration
                                                    .toString()
                                                    .split('.')
                                                    .first,
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                    ),
                              ),
                            ],
                          ),
                    ),
              ),
            ),
            SizedBox(
              width: MediaQuery.sizeOf(context).height / 4,
              child: ValueListenableBuilder<double>(
                valueListenable: player.volume,
                builder:
                    (BuildContext context, double volume, Widget? child) =>
                        ValueListenableBuilder<bool>(
                          valueListenable: player.isMuted,
                          builder:
                              (
                                BuildContext context,
                                bool isMuted,
                                Widget? child,
                              ) => Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isMuted
                                          ? Icons.volume_off_rounded
                                          : switch (volume) {
                                            0 => Icons.volume_off_rounded,
                                            < 0.3 => Icons.volume_mute_rounded,
                                            < 0.6 => Icons.volume_down_rounded,
                                            _ => Icons.volume_up_rounded,
                                          },
                                    ),
                                    color: Colors.white60,
                                    iconSize: 30,
                                    onPressed: () => player.switchIsMuted(),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: isMuted ? 0.0 : volume,
                                      onChanged:
                                          (value) => player.setVolume(value),
                                      onChangeEnd:
                                          (value) =>
                                              player.setVolumeSettings(value),
                                      min: 0.0,
                                      max: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                        ),
              ),
            ),
          ],
        );
      } else if (snapshot.hasError &&
          snapshot.connectionState == ConnectionState.done) {
        return Text('Error occured');
      } else {
        return LoadingScreen();
      }
    },
  );
}
