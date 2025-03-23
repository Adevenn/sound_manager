import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model.dart';

import 'uuid.dart';

class Playlist {
  late final String id;
  String name;
  File? _file;
  final ValueNotifier<List<Soundtrack>> _tracks = ValueNotifier([]);
  ValueNotifier<List<Soundtrack>> get tracks => _tracks;
  ValueNotifier<int> _trackIndex = ValueNotifier(0);
  bool isLoop = false;
  ValueNotifier<int> get trackIndex => _trackIndex;
  bool get isTracksNotEmpty => _tracks.value.isNotEmpty;
  bool get isPreviousTrack => _trackIndex.value > 0;
  bool get isNextTrack => _trackIndex.value < _tracks.value.length - 1;
  Soundtrack? get previousSoundtrack =>
      isPreviousTrack ? _tracks.value[_trackIndex.value - 1] : null;
  Soundtrack? get actualSoundtrack =>
      isTracksNotEmpty ? _tracks.value[_trackIndex.value] : null;
  Soundtrack? get nextSoundtrack =>
      isNextTrack ? _tracks.value[_trackIndex.value + 1] : null;

  Playlist.empty(this.name) : id = '';

  Playlist._full(
    this.id,
    this.name,
    this._trackIndex,
    List<Soundtrack> tracks,
  ) {
    _tracks.value = List.from(tracks);
  }

  Playlist.copy(Playlist other)
    : this._full(other.id, other.name, other._trackIndex, other._tracks.value);

  Playlist.create(this.name) : id = uuid.v4() {
    create();
  }

  Playlist.fromFile(this.name) {
    _loadContent();
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

  Future<void> create() async {
    _file = File('${(await directory).path}/$name.json')..createSync();
    _file!.writeAsString(jsonEncode(toJson()));
  }

  void _fromJson() {
    var json = jsonDecode(_file!.readAsStringSync());
    id = json['id'];
    name = json['name'];
    _tracks.value.clear();
    for (var sound in json['sounds']) {
      _tracks.value.add(Soundtrack.fromJson(sound));
    }
    _trackIndex = json['index'];
  }

  Future<void> _loadContent() async {
    try {
      _file = File('${(await directory).path}/$name.json');
      _fromJson();
    } catch (e) {
      Future.error(e);
    }
  }

  void save() async {
    _file!.writeAsString(jsonEncode(toJson()));
  }

  void rename(String newName) {
    name = newName;
  }

  void delete() {}

  void addSoundtrack(String path) {
    _tracks.value.add(Soundtrack(path, SoundtrackType.local));
  }

  void previousTrack() {
    if (isPreviousTrack) {
      _trackIndex.value--;
    }
  }

  void nextTrack() {
    if (isNextTrack) {
      _trackIndex.value++;
    }
    if (isLoop) {
      _trackIndex.value = 0;
    }
  }

  ///Compare 2 playlists. Returns true if identical
  bool compare(Playlist other) {
    if (id != other.id ||
        name != other.name ||
        _trackIndex != other._trackIndex ||
        _tracks.value.length != other._tracks.value.length) {
      return false;
    }
    for (int i = 0; i < _tracks.value.length; i++) {
      if (_tracks.value[i].source != other._tracks.value[i].source ||
          _tracks.value[i].type != other._tracks.value[i].type) {
        return false;
      }
    }
    return true;
  }
}
