import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model.dart';

import 'uuid.dart';

class Playlist {
  late final String id;
  String _name;
  String get name => _name;
  File? _file;
  final List<Soundtrack> _tracks = [];
  List<Soundtrack> get tracks => _tracks;
  final ValueNotifier<int> _trackIndex = ValueNotifier(0);
  ValueNotifier<int> get trackIndex => _trackIndex;
  int get length => tracks.length;
  bool isPlaylistLoop = false;
  bool get isNotEmpty => _tracks.isNotEmpty;
  bool get isPreviousTrack => _trackIndex.value > 0;
  bool get isNextTrack => _trackIndex.value < _tracks.length - 1;
  Soundtrack? get actualSoundtrack =>
      isNotEmpty ? _tracks[_trackIndex.value] : null;

  Playlist.empty(this._name) : id = uuid.v4();

  ///Bare constructor used by [fromFile]; [id] is filled in by [_loadContent].
  Playlist._forLoad(this._name);

  //Careful, create() is async
  Playlist.create(this._name) : id = uuid.v4() {
    _create();
  }

  Future<void> _create() async {
    _file = File('${(await directory).path}/$name.json')..createSync();
    _file!.writeAsString(jsonEncode(toJson()));
  }

  ///Loads a playlist from its `$name.json` file. Use this instead of an
  ///async constructor so the tracks are fully loaded before the object is used.
  static Future<Playlist> fromFile(String name) async {
    final playlist = Playlist._forLoad(name);
    await playlist._loadContent();
    return playlist;
  }

  ///Loads the file and extract data from the json inside
  Future<void> _loadContent() async {
    try {
      _file = File('${(await directory).path}/$name.json');
      var json = jsonDecode(_file!.readAsStringSync());
      id = json['id'];
      _name = json['name'];
      _tracks.clear();
      for (var sound in json['sounds']) {
        _tracks.add(Soundtrack.fromJson(sound));
      }
      _trackIndex.value = json['index'];
    } catch (e) {
      Future.error(e);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sounds': _tracks.map((s) => s.toJson()).toList(),
    'index': _trackIndex.value,
  };

  Future<Directory> get directory async {
    final directory = await getApplicationSupportDirectory();
    final directoryData = await Directory('${directory.path}/Data').create();
    return Directory('${directoryData.path}/Playlist')..createSync();
  }

  ///Rename the playlist
  void rename(String newName) {
    _name = newName;
  }

  ///Save the playlist in a file
  void save() async {
    _file!.writeAsString(jsonEncode(toJson()));
  }

  void addSoundtrack(String path) =>
      _tracks.add(Soundtrack(path, SoundtrackType.local));

  void removeTrack(int index) => _tracks.removeAt(index);

  void changeTrack(int index) => trackIndex.value = index;

  void previousTrack() {
    if (isPreviousTrack) {
      _trackIndex.value--;
    }
  }

  ///Advances to the next track. Returns false when the end of the playlist is
  ///reached and looping is disabled (i.e. there is nothing more to play).
  bool nextTrack() {
    if (isNextTrack) {
      _trackIndex.value++;
      return true;
    }
    if (isPlaylistLoop) {
      _trackIndex.value = 0;
      return true;
    }
    return false;
  }

  ///Compare 2 playlists. Returns true if identical.
  bool compare(Playlist other) {
    if (id != other.id ||
        name != other.name ||
        _trackIndex.value != other._trackIndex.value ||
        _tracks.length != other._tracks.length) {
      return false;
    }
    for (int i = 0; i < _tracks.length; i++) {
      if (!_tracks[i].compare(other._tracks[i])) {
        return false;
      }
    }
    return true;
  }
}
