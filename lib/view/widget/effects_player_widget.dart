import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/theme/app_theme.dart';
import 'package:sound_manager/view/widget/audio_volume_widget.dart';
import 'package:sound_manager/view/widget/effect_chip_widget.dart';
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
                          title: const Text('Hold = loop'),
                          subtitle: const Text(
                            'Loops while the button is held down',
                          ),
                          value: track.loop,
                          onChanged:
                              (v) => setDialog(() => track.loop = v),
                        ),
                        const SizedBox(height: 8),
                        const Text('Color'),
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
                                              ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                              : Theme.of(
                                                context,
                                              ).colorScheme.outlineVariant,
                                      width: track.colorIndex == i ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Icon'),
                        Wrap(
                          children: [
                            for (int i = 0; i < EffectStyle.icons.length; i++)
                              IconButton(
                                icon: Icon(EffectStyle.icons[i]),
                                color:
                                    track.iconIndex == i
                                        ? PlayerType.effect.style.color
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
                      child: const Text('Close'),
                    ),
                  ],
                ),
          ),
    );
    // Persist (best effort) and refresh the soundboard.
    await player.playlist.save();
    if (mounted) setState(() {});
  }

  Color get _accent => player.type.style.color;

  /// Accent strip identifying the soundboard, with the loaded playlist name,
  /// channel volume and the playlist editor button.
  Widget _effectsHeader(BuildContext context) {
    final name = player.playlist.name.isEmpty ? '—' : player.playlist.name;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 2, 8, 2),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: _accent.withValues(alpha: 0.55), width: 2),
        ),
      ),
      child: Row(
        children: [
          Icon(player.type.style.icon, color: _accent, size: 20),
          const SizedBox(width: 8),
          Text(
            player.type.style.label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(width: 150, child: AudioVolumeWidget(player: player)),
          const SizedBox(width: 4),
          PlaylistButtonWidget(
            player: player,
            callback: () => setState(() => ()),
          ),
        ],
      ),
    );
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
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _effectsHeader(context),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 64,
                            maxHeight: 180,
                          ),
                          child:
                              player.playlist.isEmpty
                                  ? const Center(child: Text('No effect'))
                                  : Align(
                                    alignment: Alignment.topLeft,
                                    child: SingleChildScrollView(
                                      child: Wrap(
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: [
                                          for (final track in player.tracks)
                                            EffectChip(
                                              track: track,
                                              onTrigger:
                                                  () =>
                                                      player.playEffect(track),
                                              onConfig:
                                                  () => _configEffect(track),
                                              onHoldStart:
                                                  () => _startLoop(track),
                                              onHoldEnd: () => _stopLoop(track),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
          );
        } else if (snapshot.hasError &&
            snapshot.connectionState == ConnectionState.done) {
          return Text('An error occurred');
        } else {
          return LoadingScreen();
        }
      },
    );
  }
}
