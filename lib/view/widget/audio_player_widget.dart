import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/theme/app_theme.dart';
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

  /// Accent colour that gives this channel its identity (active toggles,
  /// selected track, header).
  Color get _accent => player.type.style.color;

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
          color:
              mode == LoopMode.none
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : _accent,
          onPressed: () => playlist.cycleLoop(),
        ),
  );

  Widget get _shuffleButton => ValueListenableBuilder<bool>(
    valueListenable: playlist.shuffle,
    builder:
        (context, on, child) => IconButton(
          tooltip: 'Shuffle',
          icon: Icon(Icons.shuffle_rounded, size: 26),
          color:
              on ? _accent : Theme.of(context).colorScheme.onSurfaceVariant,
          onPressed: () => playlist.toggleShuffle(),
        ),
  );

  Widget get _fadeButton => ValueListenableBuilder<bool>(
    valueListenable: player.fadeEnabled,
    builder:
        (context, fade, child) => IconButton(
          tooltip: 'Fade',
          icon: Icon(Icons.graphic_eq_rounded, size: 28),
          color:
              fade ? _accent : Theme.of(context).colorScheme.onSurfaceVariant,
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
                            style: const TextStyle(fontSize: 12.0),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _accent,
                                thumbColor: _accent,
                              ),
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
                          ),
                          Text(
                            duration.toString().split('.').first,
                            style: const TextStyle(fontSize: 12.0),
                          ),
                        ],
                      ),
            ),
  );

  /// Accent-tinted strip at the top of the panel: makes each channel a clearly
  /// delimited box and surfaces the loaded playlist name.
  Widget _channelHeader(BuildContext context) {
    final name = playlist.name.isEmpty ? '—' : playlist.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: _accent.withValues(alpha: 0.55), width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(player.type.style.icon, color: _accent, size: 20),
          const SizedBox(width: 8),
          Text(
            player.type.style.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Scrollable track list with the currently-playing track highlighted.
  Widget _trackList() => ListenableBuilder(
    // Rebuild on track change too: tapping a duplicate-named track changes the
    // index but not the path, so listening to path alone would not refresh the
    // selection. Also rebuild when the set of missing files is recomputed.
    listenable: Listenable.merge([
      player.path,
      playlist.trackIndex,
      player.missingTrackIds,
    ]),
    builder: (BuildContext context, Widget? child) {
      if (player.playlist.isEmpty) {
        return const Center(child: Text('No track'));
      }
      final missing = player.missingTrackIds.value;
      final errorColor = Theme.of(context).colorScheme.error;
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: player.playlist.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final track = player.playlist.tracks[index];
          final playing = track.id == player.playlist.actualSoundtrack?.id;
          final isMissing = missing.contains(track.id);
          return ListTile(
            dense: true,
            selected: playing,
            selectedColor: _accent,
            selectedTileColor: _accent.withValues(alpha: 0.12),
            leading:
                isMissing
                    ? Icon(
                      Icons.error_outline_rounded,
                      color: errorColor,
                      size: 20,
                    )
                    : playing
                    ? Icon(Icons.equalizer_rounded, color: _accent, size: 20)
                    : const Icon(Icons.music_note_rounded, size: 20),
            title: Text(
              track.name,
              style: TextStyle(
                fontSize: 14,
                color: isMissing ? errorColor : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            subtitle:
                isMissing
                    ? Text(
                      'File not found',
                      style: TextStyle(color: errorColor, fontSize: 11),
                    )
                    : null,
            onTap: () => player.changeTrack(track),
          );
        },
      );
    },
  );

  /// Transport (centered) + a tight timer/volume line.
  Widget _controlBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: ListenableBuilder(
      // Listen to both playback state (play/pause icon) and the track index
      // (prev/next enabled state), since skipping between two playing tracks
      // leaves the state unchanged and would not trigger a rebuild.
      listenable: Listenable.merge([player.state, playlist.trackIndex]),
      builder:
          (BuildContext context, Widget? child) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
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
              Row(
                children: [
                  Expanded(child: _timer),
                  SizedBox(width: 140, child: AudioVolumeWidget(player: player)),
                ],
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
              (context, child) => Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _channelHeader(context),
                    Expanded(child: _trackList()),
                    _controlBar(),
                  ],
                ),
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
