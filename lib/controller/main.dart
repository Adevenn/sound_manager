import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/theme/app_theme.dart';
import 'package:sound_manager/view/settings_screen.dart';
import 'package:sound_manager/view/widget/audio_player_widget.dart';
import 'package:sound_manager/view/widget/effects_player_widget.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the shared preferences once so all settings classes can read/write
  // synchronously afterwards.
  await Prefs.init();
  AudioSettings.instance.load();
  ShortcutSettings.instance.load();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      title: 'Sound Manager',
      minimumSize: Size(800, 600),
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  runApp(SoundManagerApp());
}

class SoundManagerApp extends StatelessWidget {
  const SoundManagerApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.dark(),
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

  late final List<AudioPlayerManager> _managers = [
    ambiancePlayer,
    musicPlayer,
    effectPlayer,
  ];

  bool get _isAnyPlaying => ambiancePlayer.isPlaying || musicPlayer.isPlaying;

  /// Global pause/play for the ambiance and music channels (effects excluded):
  /// pauses both if anything is playing, otherwise resumes both.
  void togglePlayPauseAll() {
    if (_isAnyPlaying) {
      ambiancePlayer.pause();
      musicPlayer.pause();
    } else {
      ambiancePlayer.resume();
      musicPlayer.resume();
    }
  }

  /// Triggers the [index]-th effect (bound to keyboard digits 1-9).
  void _triggerEffect(int index) {
    if (index < effectPlayer.tracks.length) {
      effectPlayer.playEffect(effectPlayer.tracks[index]);
    }
  }

  // -- Scenes ---------------------------------------------------------------

  Future<void> _saveCurrentAsScene(String name) async {
    final playlists = <String, String>{};
    final volumes = <String, double>{};
    for (final m in _managers) {
      if (m.playlist.isNotEmpty) await PlaylistRepository.save(m.playlist);
      playlists[m.type.name] = m.playlist.name;
      volumes[m.type.name] = m.volume.value;
    }
    await SceneManager.add(
      Scene(name: name, playlists: playlists, volumes: volumes),
    );
  }

  Future<void> _applyScene(Scene scene) async {
    for (final m in _managers) {
      final vol = scene.volumes[m.type.name];
      if (vol != null) m.setVolume(vol);
      await m.applyPlaylist(
        scene.playlists[m.type.name],
        autoplay: m.type != PlayerType.effect,
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _promptSaveScene() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save scene'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Scene name'),
              onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.of(context).pop(controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (name != null && name.isNotEmpty) {
      await _saveCurrentAsScene(name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scene "$name" saved')),
        );
      }
    }
  }

  Future<void> _openScenesDialog() async {
    var scenes = await SceneManager.list();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialog) => AlertDialog(
                  title: const Text('Scenes'),
                  content: SizedBox(
                    width: 360,
                    child:
                        scenes.isEmpty
                            ? const Text('No saved scene')
                            : ListView(
                              shrinkWrap: true,
                              children: [
                                for (final scene in scenes)
                                  ListTile(
                                    leading: const Icon(Icons.movie_rounded),
                                    title: Text(scene.name),
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      _applyScene(scene);
                                    },
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      onPressed: () async {
                                        await SceneManager.delete(scene.name);
                                        scenes = await SceneManager.list();
                                        setDialog(() {});
                                      },
                                    ),
                                  ),
                              ],
                            ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _promptSaveScene();
                      },
                      child: const Text('Save current scene'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  void dispose() {
    ambiancePlayer.dispose();
    musicPlayer.dispose();
    effectPlayer.dispose();
    super.dispose();
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts {
    final s = ShortcutSettings.instance;
    return {
      SingleActivator(s.playPauseAll): togglePlayPauseAll,
      for (int i = 0; i < s.effectKeys.length; i++)
        if (s.effectKeys[i] != null)
          SingleActivator(s.effectKeys[i]!): () => _triggerEffect(i),
    };
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Sound Manager'),
      actions: [
        ListenableBuilder(
          listenable: Listenable.merge([
            ambiancePlayer.state,
            musicPlayer.state,
          ]),
          builder: (context, child) {
            final playing = _isAnyPlaying;
            return TextButton.icon(
              onPressed: togglePlayPauseAll,
              icon: Icon(
                playing
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
              ),
              label: Text(playing ? 'Pause all' : 'Play all'),
            );
          },
        ),
        IconButton(
          tooltip: 'Scenes',
          icon: const Icon(Icons.movie_rounded),
          onPressed: _openScenesDialog,
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed:
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListenableBuilder(
      listenable: ShortcutSettings.instance.revision,
      builder:
          (context, child) => CallbackShortcuts(
            bindings: _shortcuts,
            child: Focus(autofocus: true, child: child!),
          ),
      child: Column(
        children: [
          // Ambiance and Music run in parallel — side by side, each with its
          // own tall track list and controls.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: AudioPlayerWidget(player: ambiancePlayer)),
                Expanded(child: AudioPlayerWidget(player: musicPlayer)),
              ],
            ),
          ),
          // Effects: a full-width soundboard docked at the bottom, always
          // visible.
          EffectsPlayerWidget(player: effectPlayer),
        ],
      ),
    ),
  );
}
