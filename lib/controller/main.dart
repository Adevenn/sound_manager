import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/audio_player_screen.dart';
import 'package:window_size/window_size.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    setWindowTitle('Sound Manager');
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
  final ambiancePlayer = PlaylistManager(type: PlayerType.ambiance);
  final musicPlayer = PlaylistManager(type: PlayerType.music);
  final effectPlayer = PlaylistManager(type: PlayerType.effect);

  void pauseAll() {
    ambiancePlayer.pause;
    musicPlayer.pause;
    effectPlayer.pause;
  }

  @override
  void dispose() {
    ambiancePlayer.dispose();
    musicPlayer.dispose();
    effectPlayer.dispose();
    super.dispose();
  }

  Widget buildPresset() {
    return Container();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Sound Manager'),
      actions: [
        ElevatedButton(onPressed: pauseAll, child: Icon(Icons.pause_rounded)),
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
              child: AudioPlayerScreen(manager: ambiancePlayer),
            ),
            Divider(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 3.56,
              child: AudioPlayerScreen(manager: musicPlayer),
            ),
            Divider(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 3.56,
              child: AudioPlayerScreen(manager: effectPlayer),
            ),
          ],
        ),
      ),
    ),
  );
}
