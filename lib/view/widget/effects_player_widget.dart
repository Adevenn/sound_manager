import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/theme/app_theme.dart';
import 'package:sound_manager/view/widget/audio_volume_widget.dart';
import 'package:sound_manager/view/widget/channel_drop_target.dart';
import 'package:sound_manager/view/widget/effect_chip_widget.dart';
import 'package:sound_manager/view/widget/playlist_button_widget.dart';

class EffectsPlayerWidget extends StatefulWidget {
  final AudioPlayerManager player;
  final GenerativeTrigger generative;

  const EffectsPlayerWidget({
    super.key,
    required this.player,
    required this.generative,
  });

  @override
  State<StatefulWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<EffectsPlayerWidget> {
  AudioPlayerManager get player => widget.player;

  late final Future<void> _settingsFuture = player.loadSettings();

  /// Loop effects currently held down, keyed by soundtrack id.
  final Map<String, AudioPlayer> _held = {};

  /// Current soundboard bank (page) index.
  int _page = 0;

  @override
  void initState() {
    super.initState();
    player.lastError.addListener(_onPlayerError);
  }

  @override
  void dispose() {
    player.lastError.removeListener(_onPlayerError);
    for (final p in _held.values) {
      player.stopLoopEffect(p);
    }
    _held.clear();
    super.dispose();
  }

  /// Surfaces effect playback failures (missing file, unplayable URL…).
  void _onPlayerError() {
    final msg = player.lastError.value;
    if (msg == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
                          onChanged: (v) => setDialog(() => track.volume = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hold = loop'),
                          subtitle: const Text(
                            'Loops while the button is held down',
                          ),
                          value: track.loop,
                          onChanged: (v) => setDialog(() => track.loop = v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Generative'),
                          subtitle: const Text(
                            'Part of the random ambiance pool',
                          ),
                          value: track.generative,
                          onChanged:
                              (v) => setDialog(() => track.generative = v),
                        ),
                        const SizedBox(height: 8),
                        const Text('Color'),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (int i = 0; i < EffectStyle.colors.length; i++)
                              GestureDetector(
                                onTap:
                                    () => setDialog(() => track.colorIndex = i),
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
    // Persist (best effort) and refresh the soundboard. Also remember this as
    // the channel's current playlist so the configured board is restored on the
    // next launch (the per-channel default name keeps it from clobbering the
    // other channels' files).
    await PlaylistRepository.save(player.playlist);
    await UserSettings.setCurrentPlaylist(player.type, player.playlist.name);
    if (mounted) setState(() {});
  }

  Color get _accent => player.type.style.color;

  /// Accent strip identifying the soundboard: name, generative countdown,
  /// stop-all, channel volume and the playlist editor button.
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
          _generativeBadge(),
          IconButton(
            tooltip: 'Stop all effects',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: () => player.stopEffects(),
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

  /// Live countdown chip while generative mode is running.
  Widget _generativeBadge() => ValueListenableBuilder<bool>(
    valueListenable: widget.generative.enabled,
    builder: (context, on, child) {
      if (!on) return const SizedBox.shrink();
      return ValueListenableBuilder<int>(
        valueListenable: widget.generative.nextInSeconds,
        builder:
            (context, secs, child) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(Icons.casino_rounded, size: 16, color: _accent),
                label: Text('${secs}s'),
              ),
            ),
      );
    },
  );

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
                (context, child) => ChannelDropTarget(
                  accent: _accent,
                  onFiles: (paths) {
                    for (final path in paths) {
                      player.playlist.addSoundtrack(path);
                    }
                    player.refreshPlaylist();
                    setState(() {});
                  },
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _effectsHeader(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child:
                              player.playlist.isEmpty
                                  ? const SizedBox(
                                    height: 64,
                                    child: Center(child: Text('No effect')),
                                  )
                                  : _soundboard(),
                        ),
                      ],
                    ),
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

  /// Paginated launchpad grid ("banks"). Columns adapt to width; a fixed number
  /// of rows per bank keeps the board compact, with ‹ 1/N › navigation.
  Widget _soundboard() {
    final tracks = player.tracks;
    return LayoutBuilder(
      builder: (context, constraints) {
        const rowsPerBank = 2;
        final columns = (constraints.maxWidth / 110).floor().clamp(2, 12);
        final pageSize = columns * rowsPerBank;
        final pageCount = (tracks.length / pageSize).ceil().clamp(1, 9999);
        if (_page >= pageCount) _page = pageCount - 1;
        final start = _page * pageSize;
        final pageTracks = tracks.skip(start).take(pageSize).toList();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              // Wide, flat pads keep the two-row board compact so the channel
              // panels above keep most of the vertical space (min height 600).
              childAspectRatio: 1.5,
              children: [
                for (final track in pageTracks)
                  EffectChip(
                    track: track,
                    onTrigger: () => player.playEffect(track),
                    onConfig: () => _configEffect(track),
                    onHoldStart: () => _startLoop(track),
                    onHoldEnd: () => _stopLoop(track),
                  ),
              ],
            ),
            if (pageCount > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed:
                          _page > 0 ? () => setState(() => _page--) : null,
                    ),
                    Text('Bank ${_page + 1} / $pageCount'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed:
                          _page < pageCount - 1
                              ? () => setState(() => _page++)
                              : null,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
