import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';

class AudioPlayerWidget extends StatelessWidget {
  final String name;
  final AudioPlayerManager player;

  const AudioPlayerWidget({
    required this.name,
    required this.player,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    spacing: 16,
    children: [
      ValueListenableBuilder<String?>(
        valueListenable: player.path,
        builder:
            (BuildContext context, String? path, Widget? child) => SizedBox(
              width: MediaQuery.sizeOf(context).width / 3.5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Flexible(
                    child: ElevatedButton(
                      onPressed: () => player.pickFile(),
                      child: Text(
                        path ?? "Aucun fichier sélectionné",
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
                              icon: Icon(Icons.skip_previous_rounded, size: 40),
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
                              icon: Icon(Icons.skip_next_rounded, size: 40),
                              onPressed: null,
                            ),
                          ],
                        ),
                        ValueListenableBuilder<Duration?>(
                          valueListenable: player.duration,
                          builder:
                              (
                                BuildContext context,
                                Duration? duration,
                                Widget? child,
                              ) => ValueListenableBuilder<Duration?>(
                                valueListenable: player.position,
                                builder:
                                    (
                                      BuildContext context,
                                      Duration? position,
                                      Widget? child,
                                    ) => Row(
                                      children: [
                                        Text(
                                          position.toString().split('.').first,
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                          ),
                                        ),
                                        Expanded(
                                          child: Slider(
                                            onChanged: (value) {
                                              if (duration == null) {
                                                return;
                                              }
                                              final position =
                                                  value *
                                                  duration.inMilliseconds;
                                              player.seek(position);
                                            },
                                            value:
                                                (position != null &&
                                                        duration != null &&
                                                        position.inMilliseconds >
                                                            0 &&
                                                        position.inMilliseconds <
                                                            duration
                                                                .inMilliseconds)
                                                    ? position.inMilliseconds /
                                                        duration.inMilliseconds
                                                    : 0.0,
                                          ),
                                        ),
                                        Text(
                                          duration.toString().split('.').first,
                                          style: const TextStyle(
                                            fontSize: 16.0,
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
                        (BuildContext context, bool isMuted, Widget? child) =>
                            Row(
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
}
