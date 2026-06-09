import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sound_manager/model.dart';

import 'uuid.dart';

/// Repeat behaviour of a playlist:
/// - [none]: stop at the end of the last track.
/// - [all]: loop the whole playlist.
/// - [one]: loop the current track forever.
enum LoopMode { none, all, one }

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

  /// Current repeat behaviour (see [LoopMode]).
  final ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.none);

  /// When enabled, [nextTrack] picks tracks in a random order.
  final ValueNotifier<bool> shuffle = ValueNotifier(false);
  final List<int> _shuffleBag = [];
  bool _shuffleExhausted = false;
  final math.Random _rng = math.Random();

  /// Cycles none -> all -> one -> none (standard media-player repeat button).
  void cycleLoop() {
    loopMode.value = switch (loopMode.value) {
      LoopMode.none => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.none,
    };
  }

  void toggleShuffle() {
    shuffle.value = !shuffle.value;
    _shuffleBag.clear();
    _shuffleExhausted = false;
  }

  /// Picks the next track index when shuffle is on. Plays every track once
  /// (a "bag"), then stops unless [LoopMode.all] is active (which reshuffles).
  bool _nextShuffle() {
    if (_tracks.length <= 1) return loopMode.value == LoopMode.all;
    if (_shuffleBag.isEmpty) {
      if (_shuffleExhausted && loopMode.value != LoopMode.all) return false;
      _shuffleBag
        ..clear()
        ..addAll([
          for (int i = 0; i < _tracks.length; i++)
            if (i != _trackIndex.value) i,
        ])
        ..shuffle(_rng);
    }
    _shuffleExhausted = _shuffleBag.length == 1;
    _trackIndex.value = _shuffleBag.removeLast();
    return true;
  }
  bool get isNotEmpty => _tracks.isNotEmpty;
  bool get isPreviousTrack => _trackIndex.value > 0;
  bool get isNextTrack => _trackIndex.value < _tracks.length - 1;
  Soundtrack? get actualSoundtrack {
    if (_tracks.isEmpty) return null;
    // Defensive clamp: the index can lag behind the list after removals.
    final i = _trackIndex.value.clamp(0, _tracks.length - 1);
    return _tracks[i];
  }

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
      final loopJson = json['loopMode'];
      if (loopJson != null) {
        loopMode.value = LoopMode.values.byName(loopJson);
      } else if (json['loop'] == true) {
        loopMode.value = LoopMode.all; // backward compat with old files
      }
      shuffle.value = json['shuffle'] ?? false;
    } catch (e, stack) {
      // Surface the failure instead of silently swallowing it so the caller's
      // FutureBuilder can show an error state.
      Error.throwWithStackTrace(e, stack);
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sounds': _tracks.map((s) => s.toJson()).toList(),
    'index': _trackIndex.value,
    'loopMode': loopMode.value.name,
    'shuffle': shuffle.value,
  };

  Future<Directory> get directory => playlistDirectory();

  /// Directory where playlists are persisted (`<appSupport>/Data/Playlist`).
  static Future<Directory> playlistDirectory() async {
    final directory = await getApplicationSupportDirectory();
    final directoryData = await Directory('${directory.path}/Data').create();
    return Directory('${directoryData.path}/Playlist')..createSync();
  }

  /// Names (without extension) of every playlist saved on disk.
  static Future<List<String>> listAll() async {
    final dir = await playlistDirectory();
    return dir
        .listSync()
        .where((f) => p.extension(f.path) == '.json')
        .map((f) => p.basenameWithoutExtension(f.path))
        .toList()
      ..sort();
  }

  /// Deletes the playlist's file from disk (if it exists).
  static Future<void> delete(String name) async {
    final file = File('${(await playlistDirectory()).path}/$name.json');
    if (file.existsSync()) await file.delete();
  }

  ///Rename the playlist
  void rename(String newName) {
    _name = newName;
  }

  ///Save the playlist in its file, creating it the first time if needed.
  Future<void> save() async {
    _file ??= File('${(await playlistDirectory()).path}/$name.json');
    await _file!.writeAsString(jsonEncode(toJson()));
  }

  ///Save the playlist under a (possibly new) name, e.g. for "save as".
  Future<void> saveAs(String newName) async {
    _name = newName;
    _file = File('${(await playlistDirectory()).path}/$newName.json');
    await _file!.writeAsString(jsonEncode(toJson()));
  }

  void addSoundtrack(String path) =>
      _tracks.add(Soundtrack(path, SoundtrackType.local));

  void removeTrack(int index) {
    _tracks.removeAt(index);
    if (_trackIndex.value >= _tracks.length) {
      _trackIndex.value = _tracks.isEmpty ? 0 : _tracks.length - 1;
    }
    _shuffleBag.clear();
  }

  void changeTrack(int index) {
    _trackIndex.value = index;
    _shuffleBag.clear();
    _shuffleExhausted = false;
  }

  /// Moves a track within the playlist (used for drag-to-reorder). Keeps the
  /// currently-selected track pointing at the same soundtrack.
  void reorderTrack(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final current = actualSoundtrack;
    final moved = _tracks.removeAt(oldIndex);
    _tracks.insert(newIndex, moved);
    if (current != null) {
      _trackIndex.value = _tracks.indexOf(current);
    }
    _shuffleBag.clear();
  }

  void previousTrack() {
    if (isPreviousTrack) {
      _trackIndex.value--;
    }
  }

  ///Advances to the next track. Returns false when the end of the playlist is
  ///reached and looping is disabled (i.e. there is nothing more to play).
  bool nextTrack() {
    if (shuffle.value) return _nextShuffle();
    if (isNextTrack) {
      _trackIndex.value++;
      return true;
    }
    if (loopMode.value == LoopMode.all) {
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
