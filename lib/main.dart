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

  Future<void> pickFile(Function(String) onFilePicked) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      onFilePicked(result.files.single.path!);
    }
  }

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

  Widget buildSoundControl(
    String label,
    AudioPlayerManager player,
    Function(String) onFilePicked,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            player.path ?? "Aucun fichier sélectionné",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          ElevatedButton(
            onPressed: () => pickFile(onFilePicked),
            child: Text("Sélectionner un fichier"),
          ),
          ValueListenableBuilder<double>(
            valueListenable: player.volume,
            builder:
                (BuildContext context, double value, Widget? child) => Slider(
                  value: player.volume.value,
                  onChanged: (value) => player.setVolume(value),
                  min: 0.0,
                  max: 1.0,
                ),
          ),
          ValueListenableBuilder<PlayerState>(
            valueListenable: player.state,
            builder:
                (BuildContext context, PlayerState value, Widget? child) => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        player.canPlay
                            ? player.isPause || player.isStop
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded
                            : Icons.play_disabled_rounded,
                      ),
                      onPressed:
                          player.canPlay
                              ? () async =>
                                  player.isPlaying
                                      ? await player.pause()
                                      : await player.play()
                              : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.stop),
                      onPressed:
                          player.isPlaying || player.isPause
                              ? () => player.stop()
                              : null,
                    ),
                  ],
                ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Gestion des Sons - JDR")),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildSoundControl(
            "Ambiance",
            ambiancePlayer,
            (p) => setState(() => ambiancePlayer.path = p),
          ),
          buildSoundControl(
            "Musique",
            musiquePlayer,
            (p) => setState(() => musiquePlayer.path = p),
          ),
          buildSoundControl(
            "Bruitages",
            bruitagesPlayer,
            (p) => setState(() => bruitagesPlayer.path = p),
          ),
          SizedBox(height: 20),
        ],
      ),
    ),
    floatingActionButton: ElevatedButton(
      onPressed: stopAll,
      child: Text("Arrêter tous les sons"),
    ),
  );
}
