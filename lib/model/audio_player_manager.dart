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
  String? path;
  final AudioPlayer _player = AudioPlayer();

  //AudioPlayer get player => _player;
  final ValueNotifier<Duration> _duration = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get duration => _duration;
  final ValueNotifier<Duration> _position = ValueNotifier<Duration>(
    Duration.zero,
  );
  ValueNotifier<Duration> get position => _position;
  String get durationText => _duration.value.toString().split('.').first;
  String get positionText => _position.value.toString().split('.').first;

  bool get canPlay => path != null;
  bool get isLoop => _player.releaseMode == ReleaseMode.loop;
  bool get isCompleted => state.value == PlayerState.completed;
  bool get isPause => state.value == PlayerState.paused;
  bool get isPlaying => state.value == PlayerState.playing;
  bool get isStop => state.value == PlayerState.stopped;

  AudioPlayerManager([this.path]) {
    state = ValueNotifier(PlayerState.stopped);
    setStreams();
  }

  void setStreams() {
    _player.onDurationChanged.listen((duration) => _duration.value = duration);
    _player.onPositionChanged.listen((p) => _position.value = p);
    _player.onPlayerComplete.listen(
      (event) => () {
        state.value = PlayerState.stopped;
        _position.value = Duration.zero;
      },
    );
    _player.onPlayerStateChanged.listen((newState) => state.value = newState);
  }

  void seek(double position) {
    _player.seek(Duration(milliseconds: position.round()));
  }

  void _changeState(PlayerState newState) {
    state.value = newState;
    notifyListeners();
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
