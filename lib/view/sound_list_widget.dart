import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sound_manager/model.dart';
import 'package:sound_manager/model/playlist.dart';
import 'package:sound_manager/view/loading.dart';

class SoundListWidget extends StatelessWidget {
  final Playlist playlist;
  final AudioPlayerManager player;
  late final ValueNotifier<Directory?> directory;
  SoundListWidget({required this.playlist, required this.player, super.key});

  Future<void> initSettings() async {
    var path = await UserSettings.getPlayerSourceDirectory(player.type);
    directory = ValueNotifier(path == null ? null : Directory(path));
  }

  List<String> getSoundPaths() {
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

  Future<void> pickDirectory() async {
    String? directoryPath = await FilePicker.platform.getDirectoryPath(
      initialDirectory: directory.value?.path,
    );
    if (directoryPath != null) {
      directory.value = Directory(directoryPath);
      UserSettings.setPlayerSourceDirectory(player.type, directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: initSettings(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done ||
          snapshot.hasData) {
        return Center(
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width / 1.2,
            height: MediaQuery.sizeOf(context).height / 1.2,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Scaffold(
                        backgroundColor: Colors.transparent,
                        appBar: AppBar(
                          automaticallyImplyLeading: false,
                          backgroundColor: Colors.transparent,
                          title: Text(
                            playlist.name,
                            style: TextStyle(fontSize: 20),
                          ),
                          actionsPadding: EdgeInsets.symmetric(horizontal: 8),
                          actions: [
                            FloatingActionButton(
                              onPressed: () => (),
                              child: Icon(Icons.save_rounded, size: 30),
                            ),
                            FloatingActionButton(
                              onPressed: () => (),
                              child: Icon(
                                Icons.library_music_rounded,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                        body: () {
                          var isHover = ValueNotifier<bool>(false);
                          return DragTarget(
                            onWillAcceptWithDetails:
                                <String>(i) => isHover.value = true,
                            onLeave: (i) => isHover.value = false,
                            onAcceptWithDetails: <String>(i) async {
                              final draggedPath = i.data;
                              if (await File(draggedPath).exists()) {}
                              isHover.value = false;
                            },
                            builder:
                                (
                                  BuildContext context,
                                  List<dynamic> accepted,
                                  List<dynamic> rejected,
                                ) =>
                                    isHover.value
                                        ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Card(
                                            color: Colors.white12,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(12.0),
                                              ),
                                            ),
                                            child: Center(
                                              child: Icon(Icons.add_rounded),
                                            ),
                                          ),
                                        )
                                        : playlist.sounds.isNotEmpty
                                        ? ListView.builder(
                                          itemCount: playlist.sounds.length,
                                          itemBuilder:
                                              (context, index) => ListTile(
                                                leading: Icon(
                                                  Icons.music_note_rounded,
                                                ),
                                                title: Text(
                                                  p.basename(
                                                    playlist
                                                        .sounds[index]
                                                        .source,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                        )
                                        : Center(
                                          child: Text(
                                            'No sound added',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                        ),
                          );
                        }(),
                      ),
                    ),
                    VerticalDivider(),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: directory,
                        builder:
                            (context, dir, child) => Scaffold(
                              backgroundColor: Colors.transparent,
                              appBar: AppBar(
                                automaticallyImplyLeading: false,
                                backgroundColor: Colors.transparent,
                                title: FloatingActionButton.extended(
                                  onPressed: () => pickDirectory(),
                                  label: Text(
                                    dir != null
                                        ? p.basename(dir.path)
                                        : 'Select a directory',
                                  ),
                                  icon: Icon(Icons.folder_rounded),
                                ),
                              ),
                              body: () {
                                var files = getSoundPaths();
                                return dir != null
                                    ? ListView.builder(
                                      itemCount: files.length,
                                      itemBuilder:
                                          (context, index) => Draggable<String>(
                                            data: files[index],
                                            dragAnchorStrategy:
                                                pointerDragAnchorStrategy,
                                            feedback: Opacity(
                                              opacity: 0.5,
                                              child: Container(
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 100,
                                                      maxWidth: 100,
                                                    ),
                                                child: Icon(
                                                  Icons.music_note_rounded,
                                                ),
                                              ),
                                            ),
                                            childWhenDragging: ListTile(),
                                            child: InkWell(
                                              onTap: () => (),
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              child: ListTile(
                                                leading: Icon(
                                                  Icons.music_note_rounded,
                                                ),
                                                title: Text(
                                                  p.basename(files[index]),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ),
                                    )
                                    : Center(
                                      child: Text(
                                        'No directory selected',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    );
                              }(),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
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
