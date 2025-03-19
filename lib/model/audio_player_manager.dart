import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sound_manager/model/user_settings.dart';

class AudioPlayerManager {
  final String _name;
  String get name => _name;
  final AudioPlayer _player = AudioPlayer();
  late final ValueNotifier<double> _volume;
  ValueNotifier<double> get volume => _volume;
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
  bool get canPlay => _path.value != null;
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get duration => _duration;
  final ValueNotifier<Duration> _position = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get position => _position;

  AudioPlayerManager(this._name, [String? path]) {
    _path = ValueNotifier(path);
    _state = ValueNotifier(PlayerState.stopped);
    _setStreams();
  }

  Future<void> loadSettings() async {
    switch (name) {
      case 'Ambiance':
        _volume = ValueNotifier<double>(await UserSettings.getAmbianceVolume());
        break;
      case 'Music':
        _volume = ValueNotifier<double>(await UserSettings.getMusicVolume());
        break;
      case 'Effect':
        _volume = ValueNotifier<double>(await UserSettings.getEffectVolume());
        break;
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

  void _setStreams() {
    _player.onDurationChanged.listen((duration) => _duration.value = duration);
    _player.onPositionChanged.listen((p) => _position.value = p);
    _player.onPlayerComplete.listen((_) {
      _position.value = Duration.zero;
      _state.value = PlayerState.completed;
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
    switch (name) {
      case 'Ambiance':
        UserSettings.setAmbianceVolume(_volume.value);
        break;
      case 'Music':
        UserSettings.setMusicVolume(_volume.value);
        break;
      case 'Effect':
        UserSettings.setEffectVolume(_volume.value);
        break;
    }
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
