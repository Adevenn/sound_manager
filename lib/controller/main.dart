import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/audio_player_widget.dart';
import 'package:window_size/window_size.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('RPG Sound Manager');
    setWindowMinSize(const Size(800, 600));
  }
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

  Widget buildPresset() {
    return Container();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Gestion des Sons - JDR"),
      actions: [
        IconButton(onPressed: stopAll, icon: Icon(Icons.stop_rounded)),
      ],
      actionsPadding: EdgeInsets.symmetric(horizontal: 8),
    ),
    drawer: Drawer(child: buildPresset()),
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 3.56,
              child: AudioPlayerWidget(
                name: "Ambiance",
                player: ambiancePlayer,
              ),
            ),
            Divider(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 3.56,
              child: AudioPlayerWidget(name: "Musique", player: musiquePlayer),
            ),
            Divider(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 3.56,
              child: AudioPlayerWidget(
                name: "Bruitages",
                player: bruitagesPlayer,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
