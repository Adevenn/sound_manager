import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
  bool get isEmpty => _tracks.isEmpty;
  bool get isPreviousTrack => _trackIndex.value > 0;
  bool get isNextTrack => _trackIndex.value < _tracks.length - 1;
  Soundtrack? get actualSoundtrack {
    if (_tracks.isEmpty) return null;
    // Defensive clamp: the index can lag behind the list after removals.
    final i = _trackIndex.value.clamp(0, _tracks.length - 1);
    return _tracks[i];
  }

  Playlist.empty(this._name) : id = uuid.v4();

  /// Rebuilds a playlist from its JSON map (as written by [toJson]). Pure: file
  /// reading lives in `PlaylistRepository`.
  Playlist.fromJson(Map<String, dynamic> json)
    : _name = json['name'] as String {
    id = json['id'] as String;
    for (final sound in (json['sounds'] as List)) {
      _tracks.add(Soundtrack.fromJson(sound));
    }
    _trackIndex.value = (json['index'] as int?) ?? 0;
    final loopJson = json['loopMode'];
    if (loopJson != null) {
      loopMode.value = LoopMode.values.byName(loopJson as String);
    } else if (json['loop'] == true) {
      loopMode.value = LoopMode.all; // backward compat with old files
    }
    shuffle.value = json['shuffle'] as bool? ?? false;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sounds': _tracks.map((s) => s.toJson()).toList(),
    'index': _trackIndex.value,
    'loopMode': loopMode.value.name,
    'shuffle': shuffle.value,
  };

  /// Renames the playlist (the on-disk file is handled by
  /// `PlaylistRepository.saveAs`).
  void rename(String newName) {
    _name = newName;
  }

  void addSoundtrack(String path) =>
      _tracks.add(Soundtrack(path, SoundtrackType.local));

  void removeTrack(int index) {
    final current = actualSoundtrack;
    final removedCurrent = identical(_tracks[index], current);
    _tracks.removeAt(index);
    if (_tracks.isEmpty) {
      _trackIndex.value = 0;
    } else if (!removedCurrent && current != null) {
      // Removing another row must not shift the selection off the track that
      // is currently playing.
      _trackIndex.value = _tracks.indexOf(current);
    } else if (_trackIndex.value >= _tracks.length) {
      _trackIndex.value = _tracks.length - 1;
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
  ///
  /// [newIndex] is the destination index **after** the item has been removed
  /// (the convention of `ReorderableListView.onReorderItem`), so no manual
  /// off-by-one correction is needed here.
  void reorderTrack(int oldIndex, int newIndex) {
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
