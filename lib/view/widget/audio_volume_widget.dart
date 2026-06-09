import 'package:flutter/material.dart';
import 'package:sound_manager/model/audio_player_manager.dart';
import 'package:sound_manager/view/theme/app_theme.dart';

class AudioVolumeWidget extends StatelessWidget {
  final AudioPlayerManager player;

  const AudioVolumeWidget({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    final accent = player.type.style.color;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return ValueListenableBuilder<double>(
      valueListenable: player.volume,
      builder:
          (BuildContext context, double volume, Widget? child) =>
              ValueListenableBuilder<bool>(
                valueListenable: player.isMuted,
                builder:
                    (BuildContext context, bool isMuted, Widget? child) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                          color: isMuted ? muted : accent,
                          iconSize: 30,
                          onPressed: () => player.switchIsMuted(),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: isMuted ? muted : accent,
                              thumbColor: isMuted ? muted : accent,
                            ),
                            child: Slider(
                              value: isMuted ? 0.0 : volume,
                              onChanged: (value) => player.setVolume(value),
                              onChangeEnd:
                                  (value) => player.setVolumeSettings(value),
                              min: 0.0,
                              max: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
              ),
    );
  }
}
