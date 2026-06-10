import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';
import 'package:sound_manager/view/theme/app_theme.dart';

class PlaylistScreen extends StatefulWidget {
  final AudioPlayerManager player;
  PlaylistScreen({required this.player, super.key});

  @override
  State<StatefulWidget> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  AudioPlayerManager get player => widget.player;
  late Playlist playlist = widget.player.playlist;
  ValueNotifier<Directory?> directory = ValueNotifier(null);

  Color get _accent => player.type.style.color;

  // Created once: building the future inside build() would re-run it on every
  // rebuild (and previously re-initialised a late-final field, which threw).
  late final Future<void> _settingsFuture = _initSettings();

  Future<void> _initSettings() async {
    var path = UserSettings.getPlayerSourceDirectory(player.type);
    directory.value = path == null ? null : Directory(path);
    await Future.wait([_scanMissing(), _scanDirectory()]);
  }

  /// Drag-over highlight of the playlist drop zone. A state field (not rebuilt
  /// on every build) so it survives rebuilds and can be disposed.
  final ValueNotifier<bool> _dropHover = ValueNotifier(false);

  @override
  void dispose() {
    directory.dispose();
    _dropHover.dispose();
    super.dispose();
  }

  /// Sources in the working playlist whose file is missing on disk, refreshed
  /// after any edit so broken tracks are flagged in the list.
  Set<String> _missingSources = {};

  Future<void> _scanMissing() async {
    final missing = <String>{};
    for (final track in playlist.tracks) {
      if (!await track.exists()) missing.add(track.source);
    }
    if (mounted) setState(() => _missingSources = missing);
  }

  /// Prompts for a name then saves the working playlist to disk and remembers
  /// it as this channel's current playlist.
  Future<void> _savePlaylistDialog() async {
    final controller = TextEditingController(text: playlist.name);
    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save playlist'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
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
    controller.dispose();
    if (name == null || name.isEmpty) return;
    await PlaylistRepository.saveAs(playlist, name);
    await UserSettings.setCurrentPlaylist(player.type, name);
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Playlist "$name" saved')));
    }
  }

  /// Lets the user pick a saved playlist (or delete one) and load it as the
  /// working playlist.
  Future<void> _loadPlaylistDialog() async {
    final names = await PlaylistRepository.listAll();
    if (!mounted) return;
    if (names.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No saved playlist')));
      return;
    }
    final chosen = await showDialog<String>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Load a playlist'),
                  content: SizedBox(
                    width: 320,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final name in names)
                          ListTile(
                            leading: const Icon(Icons.queue_music_rounded),
                            title: Text(name),
                            onTap: () => Navigator.of(context).pop(name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Delete',
                              onPressed: () async {
                                await PlaylistRepository.delete(name);
                                names.remove(name);
                                setDialogState(() {});
                              },
                            ),
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
    if (chosen == null) return;
    final Playlist loaded;
    try {
      loaded = await PlaylistRepository.load(chosen);
    } catch (_) {
      // Corrupted or unreadable file: report instead of crashing the dialog.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load playlist "$chosen"')),
        );
      }
      return;
    }
    await UserSettings.setCurrentPlaylist(player.type, chosen);
    if (mounted) {
      setState(() => playlist = loaded);
      await _scanMissing();
    }
  }

  Future<void> _pickDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath(
      initialDirectory: directory.value?.path,
    );
    if (directoryPath != null) {
      directory.value = Directory(directoryPath);
      UserSettings.setPlayerSourceDirectory(player.type, directoryPath);
      await _scanDirectory();
    }
  }

  /// Audio files found in the source directory, sorted by name. Refreshed
  /// asynchronously (off the build path) when the directory changes or on
  /// explicit refresh, so a large folder never janks the UI.
  List<String> _trackPaths = [];

  /// Case-insensitive text filters for the directory list and the playlist.
  String _dirQuery = '';
  String _plQuery = '';

  Future<void> _scanDirectory() async {
    final dir = directory.value;
    final paths = <String>[];
    if (dir != null) {
      try {
        await for (final f in dir.list()) {
          if (f is File && isAudioFile(f.path)) paths.add(f.path);
        }
      } catch (_) {
        // Directory deleted/unmounted since it was saved: show it empty.
      }
      paths.sort(
        (a, b) =>
            p.basename(a).toLowerCase().compareTo(p.basename(b).toLowerCase()),
      );
    }
    if (mounted) setState(() => _trackPaths = paths);
  }

  /// Prompts for a streaming URL and appends it as a url soundtrack.
  Future<void> _addUrlDialog() async {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add a URL stream'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: urlController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://example.com/stream.mp3',
                  ),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Add'),
              ),
            ],
          ),
    );
    final url = urlController.text.trim();
    final title = nameController.text.trim();
    urlController.dispose();
    nameController.dispose();
    if (ok == true && url.isNotEmpty) {
      setState(() {
        playlist.tracks.add(
          Soundtrack(
            url,
            SoundtrackType.url,
            title: title.isEmpty ? null : title,
          ),
        );
      });
    }
  }

  /// Compact, always-visible search box used above both lists.
  Widget _searchField({
    required String hint,
    required ValueChanged<String> onChanged,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: TextField(
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    ),
  );

  Widget get _directoryContent {
    final query = _dirQuery.toLowerCase();
    var files =
        query.isEmpty
            ? _trackPaths
            : _trackPaths
                .where((f) => p.basename(f).toLowerCase().contains(query))
                .toList();
    return Expanded(
      child: ListView.separated(
        itemCount: files.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder:
            (context, index) => Draggable<String>(
              data: files[index],
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Opacity(
                opacity: 0.5,
                child: Container(
                  constraints: const BoxConstraints(
                    maxHeight: 100,
                    maxWidth: 100,
                  ),
                  child: Icon(Icons.music_note_rounded),
                ),
              ),
              childWhenDragging: ListTile(),
              child: InkWell(
                // Second way to add a track (besides drag & drop): a single
                // click appends it to the working playlist.
                onTap: () {
                  setState(() => playlist.addSoundtrack(files[index]));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(milliseconds: 900),
                      content: Text('Added "${p.basename(files[index])}"'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12.0),
                child: ListTile(
                  leading: Icon(Icons.music_note_rounded),
                  title: Text(
                    p.basename(files[index]),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.add_circle_outline_rounded,
                    color: _accent,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget get _playlistContent => Expanded(
    child: () {
      final isHover = _dropHover;
      return DragTarget<String>(
        onWillAcceptWithDetails: (i) => isHover.value = true,
        onLeave: (i) => isHover.value = false,
        onAcceptWithDetails: (i) async {
          final draggedPath = i.data;
          if (await File(draggedPath).exists()) {
            setState(() => playlist.addSoundtrack(draggedPath));
          }
          isHover.value = false;
        },
        builder:
            (
              BuildContext context,
              List<dynamic> accepted,
              List<dynamic> rejected,
            ) => ValueListenableBuilder(
              valueListenable: isHover,
              builder:
                  (context, value, child) =>
                      value
                          ? Card(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12.0),
                              ),
                            ),
                            child: Center(
                              child: Icon(Icons.add_rounded, size: 50),
                            ),
                          )
                          : playlist.isEmpty
                          ? Center(child: Text('Drag files here'))
                          // A filter disables reordering (indices would not map
                          // back to the full list), so show a plain list while
                          // searching.
                          : _plQuery.isNotEmpty
                          ? _filteredPlaylist()
                          // Live-refresh the "now playing" marker if the track
                          // changes while this editor is open.
                          : ListenableBuilder(
                            listenable: Listenable.merge([
                              player.path,
                              player.playlist.trackIndex,
                            ]),
                            builder:
                                (context, _) => ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  itemCount: playlist.length,
                                  // Visible feedback while dragging a row:
                                  // accent-tinted, bordered, lifted card.
                                  proxyDecorator:
                                      (child, index, animation) => Material(
                                        color: Colors.transparent,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _accent.withValues(
                                              alpha: 0.20,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: _accent,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: child,
                                        ),
                                      ),
                                  onReorderItem:
                                      (oldIndex, newIndex) => setState(
                                        () => playlist.reorderTrack(
                                          oldIndex,
                                          newIndex,
                                        ),
                                      ),
                                  itemBuilder: (context, index) {
                                    final track = playlist.tracks[index];
                                    final playing =
                                        track.id ==
                                        player.playlist.actualSoundtrack?.id;
                                    final missing = _missingSources.contains(
                                      track.source,
                                    );
                                    final errorColor =
                                        Theme.of(context).colorScheme.error;
                                    return ListTile(
                                      key: ValueKey(track.id),
                                      selected: playing,
                                      selectedColor: _accent,
                                      selectedTileColor: _accent.withValues(
                                        alpha: 0.12,
                                      ),
                                      leading: ReorderableDragStartListener(
                                        index: index,
                                        child: Icon(
                                          missing
                                              ? Icons.error_outline_rounded
                                              : Icons.drag_handle_rounded,
                                          color:
                                              missing
                                                  ? errorColor
                                                  : (playing ? _accent : null),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          if (track.type == SoundtrackType.url)
                                            const Padding(
                                              padding: EdgeInsets.only(
                                                right: 6,
                                              ),
                                              child: Icon(
                                                Icons.link_rounded,
                                                size: 16,
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              track.name,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  missing
                                                      ? TextStyle(
                                                        color: errorColor,
                                                      )
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle:
                                          missing
                                              ? Text(
                                                'File not found',
                                                style: TextStyle(
                                                  color: errorColor,
                                                  fontSize: 11,
                                                ),
                                              )
                                              : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (playing)
                                            Icon(
                                              Icons.equalizer_rounded,
                                              color: _accent,
                                              size: 20,
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                            tooltip: 'Remove',
                                            onPressed:
                                                () => setState(
                                                  () => playlist.removeTrack(
                                                    index,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                          ),
            ),
      );
    }(),
  );

  /// Read-only filtered view of the working playlist (used while a filter query
  /// is active). Matches on the track display name; the "now playing" marker
  /// and a remove button are kept.
  Widget _filteredPlaylist() {
    final query = _plQuery.toLowerCase();
    final matches = <int>[
      for (var i = 0; i < playlist.length; i++)
        if (playlist.tracks[i].name.toLowerCase().contains(query)) i,
    ];
    if (matches.isEmpty) {
      return const Center(child: Text('No match'));
    }
    return ListenableBuilder(
      listenable: Listenable.merge([player.path, player.playlist.trackIndex]),
      builder:
          (context, _) => ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final index = matches[i];
              final track = playlist.tracks[index];
              final playing = track.id == player.playlist.actualSoundtrack?.id;
              final missing = _missingSources.contains(track.source);
              final errorColor = Theme.of(context).colorScheme.error;
              return ListTile(
                selected: playing,
                selectedColor: _accent,
                selectedTileColor: _accent.withValues(alpha: 0.12),
                leading: Icon(
                  track.type == SoundtrackType.url
                      ? Icons.link_rounded
                      : missing
                      ? Icons.error_outline_rounded
                      : Icons.music_note_rounded,
                  color: missing ? errorColor : (playing ? _accent : null),
                ),
                title: Text(
                  track.name,
                  overflow: TextOverflow.ellipsis,
                  style: missing ? TextStyle(color: errorColor) : null,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  tooltip: 'Remove',
                  onPressed: () => setState(() => playlist.removeTrack(index)),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _settingsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done ||
          snapshot.hasData) {
        // The editor is shown as a dialog: Escape would normally pop it with a
        // null result and silently discard a playlist loaded inside the editor.
        // Intercept every pop so the working playlist is always returned.
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) Navigator.of(context).pop(playlist);
          },
          child: _buildEditor(context),
        );
      } else if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasError) {
        return Center(child: Text('An error occurred'));
      }
      return LoadingScreen();
    },
  );

  Widget _buildEditor(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(playlist),
        icon: Icon(Icons.arrow_back_rounded),
      ),
      title: Row(
        children: [
          Icon(player.type.style.icon, color: player.type.style.color),
          const SizedBox(width: 8),
          Text(player.type.style.label, style: TextStyle(fontSize: 20)),
        ],
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    FloatingActionButton(
                      heroTag: null,
                      tooltip: 'Load a playlist',
                      onPressed: _loadPlaylistDialog,
                      child: Icon(Icons.library_music_rounded, size: 30),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          playlist.name,
                          style: TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    FloatingActionButton(
                      heroTag: null,
                      tooltip: 'Add a URL stream',
                      onPressed: _addUrlDialog,
                      child: Icon(Icons.link_rounded, size: 28),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      heroTag: null,
                      tooltip: 'Save playlist',
                      onPressed: _savePlaylistDialog,
                      child: Icon(Icons.save_rounded, size: 30),
                    ),
                  ],
                ),
                _searchField(
                  hint: 'Filter playlist…',
                  onChanged: (v) => setState(() => _plQuery = v),
                ),
                Divider(),
                _playlistContent,
              ],
            ),
          ),
          VerticalDivider(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: directory,
              builder:
                  (context, dir, child) => Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            FloatingActionButton(
                              heroTag: null,
                              onPressed: () => _pickDirectory(),
                              child: Icon(Icons.folder_rounded),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                ),
                                child: Text(
                                  dir != null
                                      ? p.basename(dir.path)
                                      : 'Select a directory',
                                  style: TextStyle(fontSize: 20),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Refresh',
                              icon: const Icon(Icons.refresh_rounded),
                              onPressed: dir == null ? null : _scanDirectory,
                            ),
                          ],
                        ),
                        if (dir != null)
                          _searchField(
                            hint: 'Filter files…',
                            onChanged: (v) => setState(() => _dirQuery = v),
                          ),
                        Divider(),
                        dir != null
                            ? _directoryContent
                            : Center(
                              child: Text(
                                'No directory selected',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                      ],
                    ),
                  ),
            ),
          ),
        ],
      ),
    ),
  );
}
