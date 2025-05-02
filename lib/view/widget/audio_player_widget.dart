import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/playlist_screen.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayerManager player;
  const AudioPlayerWidget({required this.player, super.key});

  @override
  State<StatefulWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayerManager get player => widget.player;
  Playlist get playlist => widget.player.playlist;

  Widget get previousTrack => IconButton(
    icon: Icon(Icons.skip_previous_rounded, size: 40),
    onPressed: playlist.isPreviousTrack ? () => player.previousTrack() : null,
  );

  Widget get playPauseButton => IconButton(
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
            ? () async {
              player.isPlaying ? await player.pause() : await player.play();
            }
            : null,
  );

  Widget get nextTrack => IconButton(
    icon: Icon(Icons.skip_next_rounded, size: 40),
    onPressed: playlist.isNextTrack ? () => player.nextTrack() : null,
  );

  Widget get timer => ValueListenableBuilder<Duration>(
    valueListenable: player.duration,
    builder:
        (BuildContext context, Duration duration, Widget? child) =>
            ValueListenableBuilder<Duration>(
              valueListenable: player.position,
              builder:
                  (BuildContext context, Duration position, Widget? child) =>
                      Row(
                        children: [
                          Text(
                            position.toString().split('.').first,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                          Expanded(
                            child: Slider(
                              onChanged: (value) {
                                final position =
                                    value * duration.inMilliseconds;
                                player.seek(position);
                              },
                              value:
                                  (position.inMilliseconds > 0 &&
                                          position.inMilliseconds <
                                              duration.inMilliseconds)
                                      ? position.inMilliseconds /
                                          duration.inMilliseconds
                                      : 0.0,
                            ),
                          ),
                          Text(
                            duration.toString().split('.').first,
                            style: const TextStyle(fontSize: 14.0),
                          ),
                        ],
                      ),
            ),
  );

  Widget get volume => ValueListenableBuilder<double>(
    valueListenable: player.volume,
    builder:
        (BuildContext context, double volume, Widget? child) =>
            ValueListenableBuilder<bool>(
              valueListenable: player.isMuted,
              builder:
                  (BuildContext context, bool isMuted, Widget? child) => Row(
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
                          onChanged: (value) => player.setVolume(value),
                          onChangeEnd:
                              (value) => player.setVolumeSettings(value),
                          min: 0.0,
                          max: 1.0,
                        ),
                      ),
                    ],
                  ),
            ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: player.loadSettings(),
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData ||
          snapshot.connectionState == ConnectionState.done) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    player.type.name.capitalize(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      var newPlaylist = await showDialog<Playlist>(
                        context: context,
                        builder:
                            (context) => Dialog.fullscreen(
                              child: PlaylistScreen(player: player),
                            ),
                      );
                      if (newPlaylist != null &&
                          !playlist.compare(newPlaylist)) {
                        player.playlist = newPlaylist;
                        player.changeTrack(playlist.actualSoundtrack);
                      }
                      setState(() {});
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
            ),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: playlist.tracks,
                builder:
                    (context, value, child) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ValueListenableBuilder<String?>(
                              valueListenable: player.path,
                              builder:
                                  (
                                    BuildContext context,
                                    String? path,
                                    Widget? child,
                                  ) => SizedBox(
                                    height:
                                        MediaQuery.sizeOf(context).height / 3,
                                    child: player.playlist.isTracksNotEmpty
                                        ? ListView.separated(
                                          itemBuilder:
                                              (
                                                context,
                                                index,
                                              ) => ListTile(
                                                selected:
                                                    player
                                                        .playlist
                                                        .tracks
                                                        .value[index]
                                                        .id ==
                                                    player
                                                        .playlist
                                                        .actualSoundtrack!
                                                        .id,
                                                selectedColor:
                                                    Colors.green[400],
                                                title: Text(
                                                  player
                                                      .tracks
                                                      .value[index]
                                                      .name,
                                    
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                  maxLines: 2,
                                                ),
                                                onTap:
                                                    () => player
                                                        .changeTrack(
                                                          player
                                                              .playlist
                                                              .tracks
                                                              .value[index],
                                                        ),
                                              ),
                                          separatorBuilder:
                                              (context, index) =>
                                                  Divider(),
                                          itemCount:
                                              player.playlist.length,
                                        )
                                        : Center(child: Text("No track")),
                                  ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              previousTrack,
                                              playPauseButton,
                                              nextTrack,
                                            ],
                                          ),
                                          timer,
                                        ],
                                      ),
                                ),
                          ),
                        ),
                        Expanded(child: volume),
                      ],
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
