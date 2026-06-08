import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/widget/audio_volume_widget.dart';
import 'package:sound_manager/view/widget/playlist_button_widget.dart';

class EffectsPlayerWidget extends StatefulWidget {
  final AudioPlayerManager player;

  const EffectsPlayerWidget({super.key, required this.player});

  @override
  State<StatefulWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<EffectsPlayerWidget> {
  AudioPlayerManager get player => widget.player;

  late final Future<void> _settingsFuture = player.loadSettings();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _settingsFuture,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData ||
            snapshot.connectionState == ConnectionState.done) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        Text(
                          player.type.name.capitalize(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PlaylistButtonWidget(
                          player: player,
                          callback: () => setState(() => ()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child:
                        player.playlist.isNotEmpty
                            ? Wrap()
                            : Center(child: Text('No effect')),
                  ),
                  Expanded(child: AudioVolumeWidget(player: player)),
                ],
              ),
            ),
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
}
