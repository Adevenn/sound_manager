import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
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
                await player.play(short: true);
              }
            }
            : null,
  );

  Widget get _nextTrack => IconButton(
    icon: Icon(Icons.skip_next_rounded, size: 35),
    onPressed: playlist.isNextTrack ? () => player.nextTrack() : null,
  );

  Widget get _loopButton => ValueListenableBuilder<LoopMode>(
    valueListenable: playlist.loopMode,
    builder:
        (context, mode, child) => IconButton(
          tooltip: switch (mode) {
            LoopMode.none => 'Loop: off',
            LoopMode.all => 'Loop: whole playlist',
            LoopMode.one => 'Loop: current track',
          },
          icon: Icon(
            mode == LoopMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
            size: 28,
          ),
          color: mode == LoopMode.none ? Colors.white60 : Colors.green[400],
          onPressed: () => playlist.cycleLoop(),
        ),
  );

  Widget get _shuffleButton => ValueListenableBuilder<bool>(
    valueListenable: playlist.shuffle,
    builder:
        (context, on, child) => IconButton(
          tooltip: 'Shuffle',
          icon: Icon(Icons.shuffle_rounded, size: 26),
          color: on ? Colors.green[400] : Colors.white60,
          onPressed: () => playlist.toggleShuffle(),
        ),
  );

  Widget get _fadeButton => ValueListenableBuilder<bool>(
    valueListenable: player.fadeEnabled,
    builder:
        (context, fade, child) => IconButton(
          tooltip: 'Fade',
          icon: Icon(Icons.graphic_eq_rounded, size: 28),
          color: fade ? Colors.green[400] : Colors.white60,
          onPressed: () => player.toggleFade(),
        ),
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
        return ListenableBuilder(
          listenable: player.playlistRevision,
          builder:
              (context, child) => Column(
            children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListenableBuilder(
                  // Rebuild on track change too: tapping a duplicate-named
                  // track changes the index but not the path, so listening to
                  // path alone would not refresh the selection.
                  listenable: Listenable.merge([
                    player.path,
                    playlist.trackIndex,
                  ]),
                  builder:
                      (BuildContext context, Widget? child) =>
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
                      child: ListenableBuilder(
                        // Listen to both playback state (play/pause icon) and
                        // the track index (prev/next enabled state), since
                        // skipping between two playing tracks leaves the state
                        // unchanged and would not trigger a rebuild.
                        listenable: Listenable.merge([
                          player.state,
                          playlist.trackIndex,
                        ]),
                        builder:
                            (BuildContext context, Widget? child) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _loopButton,
                                    _shuffleButton,
                                    _previousTrack,
                                    _playPauseButton,
                                    _nextTrack,
                                    _fadeButton,
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
          ),
        );
      } else if (snapshot.hasError &&
          snapshot.connectionState == ConnectionState.done) {
        return Text('An error occurred');
      } else {
        return LoadingScreen();
      }
    },
  );
}
