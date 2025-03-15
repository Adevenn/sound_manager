import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sound_manager/model.dart';

void main() {
  runApp(SoundManagerApp());
}

class SoundManagerApp extends StatelessWidget {
  const SoundManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData.dark(useMaterial3: true),
    debugShowCheckedModeBanner: false,
    home: SoundManagerScreen(),
  );
}

class SoundManagerScreen extends StatefulWidget {
  const SoundManagerScreen({super.key});

  @override
  _SoundManagerScreenState createState() => _SoundManagerScreenState();
}

class _SoundManagerScreenState extends State<SoundManagerScreen> {
  final ambiancePlayer = AudioPlayerManager();
  final musiquePlayer = AudioPlayerManager();
  final bruitagesPlayer = AudioPlayerManager();

  void stopAll() {
    ambiancePlayer.stop();
    musiquePlayer.stop();
    bruitagesPlayer.stop();
  }

  @override
  void dispose() {
    ambiancePlayer.dispose();
    musiquePlayer.dispose();
    bruitagesPlayer.dispose();
    super.dispose();
  }

  Widget buildSoundControl(String label, AudioPlayerManager player) => Padding(
    padding: const EdgeInsets.all(8.0),
    child: Column(
      spacing: 8,
      children: [
        ValueListenableBuilder<String?>(
          valueListenable: player.path,
          builder:
              (BuildContext context, String? path, Widget? child) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () => player.pickFile(),
                    child: Text(path ?? "Aucun fichier sélectionné"),
                  ),
                ],
              ),
        ),
        ValueListenableBuilder<String?>(
          valueListenable: player.path,
          builder:
              (BuildContext context, String? path, Widget? child) =>
                  ValueListenableBuilder<PlayerState>(
                    valueListenable: player.state,
                    builder:
                        (
                          BuildContext context,
                          PlayerState state,
                          Widget? child,
                        ) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                              icon: Icon(Icons.stop_rounded, size: 40),
                              onPressed:
                                  player.isPlaying || player.isPause
                                      ? () => player.stop()
                                      : null,
                            ),
                          ],
                        ),
                  ),
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
                    ) => Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              position.toString().split('.').first,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            Expanded(
                              child: Slider(
                                onChanged: (value) {
                                  if (duration == null) {
                                    return;
                                  }
                                  final position =
                                      value * duration.inMilliseconds;
                                  player.seek(position);
                                },
                                value:
                                    (position != null &&
                                            duration != null &&
                                            position.inMilliseconds > 0 &&
                                            position.inMilliseconds <
                                                duration.inMilliseconds)
                                        ? position.inMilliseconds /
                                            duration.inMilliseconds
                                        : 0.0,
                              ),
                            ),
                            Text(
                              duration.toString().split('.').first,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder<double>(
                              valueListenable: player.volume,
                              builder:
                                  (
                                    BuildContext context,
                                    double volume,
                                    Widget? child,
                                  ) => Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        switch (volume) {
                                          0 => Icons.volume_off_rounded,
                                          < 0.3 => Icons.volume_mute_rounded,
                                          < 0.6 => Icons.volume_down_rounded,
                                          _ => Icons.volume_up_rounded,
                                        },
                                        color: Colors.white60,
                                        size: 30,
                                      ),
                                      Slider(
                                        value: volume,
                                        onChanged:
                                            (value) => player.setVolume(value),
                                        min: 0.0,
                                        max: 1.0,
                                      ),
                                    ],
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
              ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Gestion des Sons - JDR")),
    body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSoundControl("Ambiance", ambiancePlayer),
            Divider(),
            buildSoundControl("Musique", musiquePlayer),
            Divider(),
            buildSoundControl("Bruitages", bruitagesPlayer),
            SizedBox(height: 20),
          ],
        ),
      ),
    ),
    floatingActionButton: ElevatedButton(
      onPressed: stopAll,
      child: Text("Arrêter tous les sons"),
    ),
  );
}
