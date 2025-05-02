import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model.dart';
import 'package:path/path.dart' as p;

class AudioPlayerManager {
  final PlayerType _type;
  PlayerType get type => _type;
  final AudioPlayer _player = AudioPlayer();
  late final ValueNotifier<double> _volume;
  ValueNotifier<double> get volume => _volume;
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get duration => _duration;
  final ValueNotifier<Duration> _position = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get position => _position;
  final ValueNotifier<bool> isMuted = ValueNotifier(false);
  bool get isLoop => _player.releaseMode == ReleaseMode.loop;
  late final ValueNotifier<PlayerState> _state;
  ValueNotifier<PlayerState> get state => _state;
  bool get isCompleted => _state.value == PlayerState.completed;
  bool get isPause => _state.value == PlayerState.paused;
  bool get isPlaying => _state.value == PlayerState.playing;
  bool get isStop => _state.value == PlayerState.stopped;
  late final ValueNotifier<String?> _path;
  ValueNotifier<String?> get path => _path;

  //Playlist values
  late Playlist playlist;
  String get playlistName => playlist.name;
  ValueNotifier<List<Soundtrack>> get tracks => playlist.tracks;
  int get playlistLength => playlist.length;

  AudioPlayerManager(this._type, [String? path]) {
    _path = ValueNotifier(path);
    _state = ValueNotifier(PlayerState.stopped);
    _setStreams();
  }

  Future<void> loadSettings() async {
    _volume = ValueNotifier<double>(await UserSettings.getPlayerVolume(type));
    final currentPlaylist = await UserSettings.getCurrentPlaylist(type);
    playlist =
        currentPlaylist != ''
            ? Playlist.fromFile(currentPlaylist)
            : Playlist.empty('Custom');
  }

  void previousTrack() {
    changeTrack(playlist.previousSoundtrack);
    playlist.previousTrack();
  }

  void nextTrack() {
    changeTrack(playlist.nextSoundtrack);
    playlist.nextTrack();
  }

  void changeTrack(Soundtrack? track) {
    if (track != null) {
      for (int i = 0; i < playlist.length; i++) {
        if (track.id == playlist.tracks.value[i].id) {
          playlist.changeCurrentTrack(i);
          _path.value = track.source;
          _setStreams();
          play();
        }
      }
    } else {
      path.value = null;
    }
  }

  void addSoundtrack(String path) {
    playlist.addSoundtrack(path);
    if (playlist.length == 1) {
      _path.value = playlist.actualSoundtrack!.source;
      _setStreams();
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );
    if (result != null && result.files.single.path != null) {
      _path.value = result.files.single.path!;
    }
    _setStreams();
    await stop();
  }

  Future<List<String>> _getPlaylists() async {
    List<String> list = [];
    final files = (await playlist.directory).listSync();
    for (var f in files) {
      if (p.extension(f.path) == '.json') {
        list.add(f.path);
      }
    }
    return list;
  }

  void _setStreams() {
    _player.onDurationChanged.listen((duration) => _duration.value = duration);
    _player.onPositionChanged.listen((p) => _position.value = p);
    _player.onPlayerComplete.listen((_) {
      _position.value = Duration.zero;
      _state.value = PlayerState.completed;
      nextTrack();
    });
    _player.onPlayerStateChanged.listen((newState) => _state.value = newState);
  }

  void seek(double position) =>
      _player.seek(Duration(milliseconds: position.round()));

  void setVolume(double newValue) {
    _volume.value = newValue;
    _player.setVolume(_volume.value);
  }

  void setVolumeSettings(double value) {
    UserSettings.setPlayerVolume(type, _volume.value);
  }

  void switchIsMuted() {
    isMuted.value = !isMuted.value;
    _player.setVolume(isMuted.value ? 0.0 : _volume.value);
  }

  void _changeState(PlayerState newState) => _state.value = newState;

  void fromURL(String url) async => await _player.setSource(UrlSource(url));

  void dispose() => _player.dispose();

  Future<void> pause() async {
    await _player.pause();
    _changeState(PlayerState.paused);
  }

  Future<void> play() async {
    if (_path.value == null) return;
    try {
      await _player.setSource(DeviceFileSource(_path.value!));
      await _player.resume();
      _changeState(PlayerState.playing);
    } catch (e) {
      throw Exception('Error with the file');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _position.value = Duration.zero;
    _changeState(PlayerState.stopped);
  }
}
