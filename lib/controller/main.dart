import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/widget/audio_player_widget.dart';
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
  final ambiancePlayer = AudioPlayerManager(PlayerType.ambiance);
  final musicPlayer = AudioPlayerManager(PlayerType.music);
  final effectPlayer = AudioPlayerManager(PlayerType.effect);

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

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 2.5,
              child: AudioPlayerWidget(player: ambiancePlayer),
            ),
            Divider(),
            SizedBox(
              height: MediaQuery.sizeOf(context).height / 2.5,
              child: AudioPlayerWidget(player: musicPlayer),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Effects : WIP'),
            ),
          ],
        ),
      ),
    ),
  );
}
