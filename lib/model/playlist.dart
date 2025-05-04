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
  final ValueNotifier<List<Soundtrack>> _tracks = ValueNotifier([]);
  ValueNotifier<List<Soundtrack>> get tracks => _tracks;
  ValueNotifier<int> _trackIndex = ValueNotifier(0);
  ValueNotifier<int> get trackIndex => _trackIndex;
  int get length => tracks.value.length;
  bool isPlaylistLoop = false;
  bool get isTracksNotEmpty => _tracks.value.isNotEmpty;
  bool get isPreviousTrack => _trackIndex.value > 0;
  bool get isNextTrack => _trackIndex.value < _tracks.value.length - 1;
  Soundtrack? get actualSoundtrack =>
      isTracksNotEmpty ? _tracks.value[_trackIndex.value] : null;

  Playlist.empty(this._name) : id = uuid.v4();

  //Careful, create() is async
  Playlist.create(this._name) : id = uuid.v4() {
    _create();
  }

  Future<void> _create() async {
    _file = File('${(await directory).path}/$name.json')..createSync();
    _file!.writeAsString(jsonEncode(toJson()));
  }

  //Careful, _loadContent() is async
  Playlist.fromFile(this._name) {
    _loadContent();
  }

  ///Loads the file and extract data from the json inside
  Future<void> _loadContent() async {
    try {
      _file = File('${(await directory).path}/$name.json');
      var json = jsonDecode(_file!.readAsStringSync());
      id = json['id'];
      _name = json['name'];
      _tracks.value.clear();
      for (var sound in json['sounds']) {
        _tracks.value.add(Soundtrack.fromJson(sound));
      }
      _trackIndex = json['index'];
    } catch (e) {
      Future.error(e);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sounds': _tracks.value.map((s) => s.toJson()).toList(),
    'index': _trackIndex,
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
      _tracks.value.add(Soundtrack(path, SoundtrackType.local));

  void removeTrack(int index) => _tracks.value.removeAt(index);

  void changeTrack(int index) => trackIndex.value = index;

  void previousTrack() {
    if (isPreviousTrack) {
      _trackIndex.value--;
    }
  }

  void nextTrack() {
    if (isNextTrack) {
      _trackIndex.value++;
    }
    if (isPlaylistLoop) {
      _trackIndex.value = 0;
    }
  }

  ///Compare 2 playlists. Returns true if identical.
  bool compare(Playlist other) {
    if (id != other.id ||
        name != other.name ||
        _trackIndex != other._trackIndex ||
        _tracks.value.length != other._tracks.value.length) {
      return false;
    }
    for (int i = 0; i < _tracks.value.length; i++) {
      if (!_tracks.value[i].compare(other._tracks.value[i])) {
        return false;
      }
    }
    return true;
  }
}
