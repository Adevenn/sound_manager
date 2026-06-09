import 'package:audioplayers/audioplayers.dart';
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

  /// Loop effects currently held down, keyed by soundtrack id.
  final Map<String, AudioPlayer> _held = {};

  @override
  void dispose() {
    for (final p in _held.values) {
      player.stopLoopEffect(p);
    }
    _held.clear();
    super.dispose();
  }

  Future<void> _startLoop(Soundtrack track) async {
    if (_held.containsKey(track.id)) return;
    final p = await player.startLoopEffect(track);
    _held[track.id] = p;
  }

  Future<void> _stopLoop(Soundtrack track) async {
    final p = _held.remove(track.id);
    if (p != null) await player.stopLoopEffect(p);
  }

  Widget _effectChip(Soundtrack track) {
    final color = EffectStyle.colorAt(track.colorIndex);
    final icon = EffectStyle.iconAt(track.iconIndex);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(track.name, overflow: TextOverflow.ellipsis),
          ),
          if (track.loop) ...[
            const SizedBox(width: 4),
            const Icon(Icons.touch_app_rounded, size: 14),
          ],
        ],
      ),
    );

    // Right-click (or long-press) always opens the per-effect configuration.
    if (track.loop) {
      // Press-and-hold to loop the sound while held.
      return GestureDetector(
        onTapDown: (_) => _startLoop(track),
        onTapUp: (_) => _stopLoop(track),
        onTapCancel: () => _stopLoop(track),
        onSecondaryTap: () => _configEffect(track),
        onLongPress: () {}, // swallow long-press so hold doesn't trigger config
        child: content,
      );
    }
    return GestureDetector(
      onTap: () => player.playEffect(track),
      onSecondaryTap: () => _configEffect(track),
      onLongPress: () => _configEffect(track),
      child: content,
    );
  }

  Future<void> _configEffect(Soundtrack track) async {
    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialog) => AlertDialog(
                  title: Text(track.name, overflow: TextOverflow.ellipsis),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Volume'),
                        Slider(
                          value: track.volume,
                          onChanged:
                              (v) => setDialog(() => track.volume = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Maintenir = boucle'),
                          subtitle: const Text(
                            'Joue en boucle tant que le bouton est maintenu',
                          ),
                          value: track.loop,
                          onChanged:
                              (v) => setDialog(() => track.loop = v),
                        ),
                        const SizedBox(height: 8),
                        const Text('Couleur'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (int i = 0; i < EffectStyle.colors.length; i++)
                              GestureDetector(
                                onTap: () => setDialog(() => track.colorIndex = i),
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color:
                                        EffectStyle.colors[i] ??
                                        Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          track.colorIndex == i
                                              ? Colors.white
                                              : Colors.white24,
                                      width: track.colorIndex == i ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Icône'),
                        Wrap(
                          children: [
                            for (int i = 0; i < EffectStyle.icons.length; i++)
                              IconButton(
                                icon: Icon(EffectStyle.icons[i]),
                                color:
                                    track.iconIndex == i
                                        ? Colors.green[400]
                                        : null,
                                onPressed:
                                    () => setDialog(() => track.iconIndex = i),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer'),
                    ),
                  ],
                ),
          ),
    );
    // Persist (best effort) and refresh the soundboard.
    await player.playlist.save();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _settingsFuture,
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData ||
            snapshot.connectionState == ConnectionState.done) {
          return ListenableBuilder(
            listenable: player.playlistRevision,
            builder:
                (context, child) => Card(
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
                                  ? SingleChildScrollView(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Wrap(
                                      spacing: 8.0,
                                      runSpacing: 8.0,
                                      children: [
                                        for (final track in player.tracks)
                                          _effectChip(track),
                                      ],
                                    ),
                                  )
                                  : Center(child: Text('No effect')),
                        ),
                        Expanded(child: AudioVolumeWidget(player: player)),
                      ],
                    ),
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
