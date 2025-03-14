import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerManager extends ChangeNotifier {
  final ValueNotifier<double> _volume = ValueNotifier<double>(1.0);
  ValueNotifier<double> get volume => _volume;
  void setVolume(double newValue) {
    _volume.value = newValue;
    _player.setVolume(_volume.value);
    notifyListeners();
  }

  late ValueNotifier<PlayerState> state;
  /*ValueNotifier<PlayerState> get state =>
      ValueNotifier<PlayerState>(_player.state);*/
  String? path;
  final AudioPlayer _player = AudioPlayer();

  bool get canPlay => path != null;
  bool get isLoop => _player.releaseMode == ReleaseMode.loop;
  bool get isCompleted => state.value == PlayerState.completed;
  bool get isPause => state.value == PlayerState.paused;
  bool get isPlaying => state.value == PlayerState.playing;
  bool get isStop => state.value == PlayerState.stopped;

  void _changeState(PlayerState newState) {
    state.value = newState;
    notifyListeners();
  }

  AudioPlayerManager([this.path]) {
    state = ValueNotifier(PlayerState.stopped);
  }

  void fromFile(String path) async =>
      await _player.setSource(DeviceFileSource(path));

  void fromURL(String url) async => await _player.setSource(UrlSource(url));

  @override
  void dispose() {
    super.dispose();
    _player.dispose();
  }

  Future<void> pause() async {
    await _player.pause();
    _changeState(PlayerState.paused);
  }

  Future<void> play() async {
    if (path == null) return;
    try {
      await _player.setSource(DeviceFileSource(path!));
      await _player.resume();
      _changeState(PlayerState.playing);
    } catch (e) {
      throw Exception('Error with the file');
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _changeState(PlayerState.stopped);
  }
}
