import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/model/playlist.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/sound_list_widget.dart';

class AudioPlayerWidget extends StatelessWidget {
  final PlaylistManager manager;
  AudioPlayerManager get player => manager.player;
  Playlist get playlist => manager.playlist;

  const AudioPlayerWidget({required this.manager, super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: manager.loadSettings(),
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData ||
          snapshot.connectionState == ConnectionState.done) {
        return Row(
          spacing: 16,
          children: [
            ValueListenableBuilder<String?>(
              valueListenable: player.path,
              builder:
                  (BuildContext context, String? path, Widget? child) =>
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
                                    var result = await showDialog<double>(
                                      context: context,
                                      builder:
                                          (context) => SoundListWidget(
                                            playlist: playlist,
                                            player: player,
                                          ),
                                    );
                                    if (result != null) {}
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
                            Flexible(
                              child: ElevatedButton(
                                onPressed: () => player.pickFile(),
                                child: Text(
                                  path ?? "No file selected",
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
            Expanded(
              child: ValueListenableBuilder<String?>(
                valueListenable: player.path,
                builder:
                    (
                      BuildContext context,
                      String? path,
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
                                    onPressed: null,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      path != null
                                          ? player.isPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded
                                          : Icons.play_disabled_rounded,
                                      size: 40,
                                    ),
                                    onPressed:
                                        path != null
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
                                    onPressed: null,
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
