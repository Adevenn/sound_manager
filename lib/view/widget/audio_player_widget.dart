import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/playlist_screen.dart';
import 'package:sound_manager/view/widget/audio_volume_widget.dart';
import 'package:sound_manager/view/widget/playlist_button_widget.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AudioPlayerManager player;
  const AudioPlayerWidget({required this.player, super.key});

  @override
  State<StatefulWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  AudioPlayerManager get player => widget.player;
  Playlist get playlist => widget.player.playlist;

  late final Future<void> _settingsFuture = player.loadSettings();

  Widget get _previousTrack => IconButton(
    icon: Icon(Icons.skip_previous_rounded, size: 35),
    onPressed: playlist.isPreviousTrack ? () => player.previousTrack() : null,
  );

  Widget get _playPauseButton => IconButton(
    icon: Icon(
      playlist.isNotEmpty
          ? player.isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded
          : Icons.play_disabled_rounded,
      size: 35,
    ),
    onPressed:
        playlist.actualSoundtrack != null
            ? () async {
              if (player.isPlaying) {
                await player.pause();
              } else if (player.isPause) {
                await player.resume();
              } else {
                await player.play();
              }
            }
            : null,
  );

  Widget get _nextTrack => IconButton(
    icon: Icon(Icons.skip_next_rounded, size: 35),
    onPressed: playlist.isNextTrack ? () => player.nextTrack() : null,
  );

  Widget get _timer => ValueListenableBuilder<Duration>(
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

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _settingsFuture,
    builder: (BuildContext context, snapshot) {
      if (snapshot.hasData ||
          snapshot.connectionState == ConnectionState.done) {
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ValueListenableBuilder<String?>(
                  valueListenable: player.path,
                  builder:
                      (BuildContext context, String? path, Widget? child) =>
                          player.playlist.isNotEmpty
                              ? ListView.separated(
                                itemBuilder:
                                    (context, index) => ListTile(
                                      selected:
                                          player.playlist.tracks[index].id ==
                                          player.playlist.actualSoundtrack!.id,
                                      selectedColor: Colors.green[400],
                                      title: Text(
                                        player.tracks[index].name,
                                        style: TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      onTap:
                                          () => player.changeTrack(
                                            player.playlist.tracks[index],
                                          ),
                                    ),
                                separatorBuilder: (context, index) => Divider(),
                                itemCount: player.playlist.length,
                              )
                              : Center(child: Text("No track")),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Text(
                        player.type.name.capitalize(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: ValueListenableBuilder<PlayerState>(
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
                                    _previousTrack,
                                    _playPauseButton,
                                    _nextTrack,
                                    PlaylistButtonWidget(
                                      player: player,
                                      callback: () => setState(() => ()),
                                    ),
                                  ],
                                ),
                                _timer,
                              ],
                            ),
                      ),
                    ),
                    Expanded(child: AudioVolumeWidget(player: player)),
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
