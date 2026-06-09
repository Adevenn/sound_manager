import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sound_manager/model.dart';
import 'package:sound_manager/view/loading.dart';

//TODO: Show actual track & update state if the track changes during the screen is open
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

  // Created once: building the future inside build() would re-run it on every
  // rebuild (and previously re-initialised a late-final field, which threw).
  late final Future<void> _settingsFuture = _initSettings();

  Future<void> _initSettings() async {
    var path = await UserSettings.getPlayerSourceDirectory(player.type);
    directory.value = path == null ? null : Directory(path);
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
    if (name == null || name.isEmpty) return;
    await playlist.saveAs(name);
    await UserSettings.setCurrentPlaylist(player.type, playlist);
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
    final names = await Playlist.listAll();
    if (!mounted) return;
    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved playlist')),
      );
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
                                await Playlist.delete(name);
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
    final loaded = await Playlist.fromFile(chosen);
    await UserSettings.setCurrentPlaylist(player.type, loaded);
    if (mounted) setState(() => playlist = loaded);
  }

  Future<void> _pickDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath(
      initialDirectory: directory.value?.path,
    );
    if (directoryPath != null) {
      directory.value = Directory(directoryPath);
      UserSettings.setPlayerSourceDirectory(player.type, directoryPath);
    }
  }

  // Cache the directory scan so it does not hit the disk synchronously on every
  // rebuild (the getter is read from build()). Recomputed only when the
  // directory changes.
  String? _cachedDirPath;
  List<String> _cachedTrackPaths = [];

  List<String> _getTrackPaths() {
    final dir = directory.value;
    if (dir == null) return [];
    if (dir.path == _cachedDirPath) return _cachedTrackPaths;
    final list = <String>[];
    for (var f in dir.listSync()) {
      final ext = p.extension(f.path).toLowerCase();
      if (ext == '.mp3' || ext == '.wav') list.add(f.path);
    }
    _cachedDirPath = dir.path;
    _cachedTrackPaths = list;
    return list;
  }

  Widget get _directoryContent {
    var files = _getTrackPaths();
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
                onTap: () => (),
                borderRadius: BorderRadius.circular(12.0),
                child: ListTile(
                  leading: Icon(Icons.music_note_rounded),
                  title: Text(
                    p.basename(files[index]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget get _playlistContent => Expanded(
    child: () {
      var isHover = ValueNotifier<bool>(false);
      return DragTarget(
        onWillAcceptWithDetails: <String>(i) => isHover.value = true,
        onLeave: (i) => isHover.value = false,
        onAcceptWithDetails: <String>(i) async {
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
                          : playlist.isNotEmpty
                          ? ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: playlist.length,
                            onReorder:
                                (oldIndex, newIndex) => setState(
                                  () =>
                                      playlist.reorderTrack(oldIndex, newIndex),
                                ),
                            itemBuilder:
                                (context, index) => ListTile(
                                  key: ValueKey(playlist.tracks[index].id),
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle_rounded),
                                  ),
                                  title: Text(
                                    p.basename(playlist.tracks[index].source),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    tooltip: 'Remove',
                                    onPressed:
                                        () => setState(
                                          () => playlist.removeTrack(index),
                                        ),
                                  ),
                                ),
                          )
                          : Center(
                            child: Text('Drag files here'),
                          ),
            ),
      );
    }(),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _settingsFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done ||
          snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(playlist),
              icon: Icon(Icons.arrow_back_rounded),
            ),
            title: Text(
              player.type.name.capitalize(),
              style: TextStyle(fontSize: 20),
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
                            tooltip: 'Save playlist',
                            onPressed: _savePlaylistDialog,
                            child: Icon(Icons.save_rounded, size: 30),
                          ),
                        ],
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
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Text(
                                      dir != null
                                          ? p.basename(dir.path)
                                          : 'Select a directory',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
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
      } else if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasError) {
        return Center(child: Text('An error occurred'));
      }
      return LoadingScreen();
    },
  );
}
