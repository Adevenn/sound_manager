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
  late final ValueNotifier<Directory?> directory;

  Future<void> _initSettings() async {
    var path = await UserSettings.getPlayerSourceDirectory(player.type);
    directory = ValueNotifier(path == null ? null : Directory(path));
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

  List<String> _getTrackPaths() {
    List<String> list = [];
    if (directory.value != null) {
      final files = directory.value!.listSync();
      for (var f in files) {
        if (p.extension(f.path) == '.mp3' || p.extension(f.path) == '.wav') {
          list.add(f.path);
        }
      }
    }
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
    child: ValueListenableBuilder(
      valueListenable: player.tracks,
      builder:
          (context, sounds, child) => () {
            var isHover = ValueNotifier<bool>(false);
            return DragTarget(
              onWillAcceptWithDetails: <String>(i) => isHover.value = true,
              onLeave: (i) => isHover.value = false,
              onAcceptWithDetails: <String>(i) async {
                final draggedPath = i.data;
                if (await File(draggedPath).exists()) {
                  player.addSoundtrack(draggedPath);
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
                                : sounds.isNotEmpty
                                ? ListView.separated(
                                  itemCount: sounds.length,
                                  separatorBuilder:
                                      (context, index) => Divider(),
                                  itemBuilder:
                                      (context, index) => ListTile(
                                        leading: Icon(Icons.music_note_rounded),
                                        title: Text(
                                          p.basename(sounds[index].source),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                )
                                : Container(),
                  ),
            );
          }(),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _initSettings(),
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
                            onPressed: () => (),
                            child: Icon(Icons.library_music_rounded, size: 30),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                player.playlistName,
                                style: TextStyle(fontSize: 20),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          FloatingActionButton(
                            onPressed: () => (),
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
        return Center(child: Text('Error occured'));
      }
      return LoadingScreen();
    },
  );
}
