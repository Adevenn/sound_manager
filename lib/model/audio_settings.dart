import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, app-wide audio settings (shared by every channel): master volume,
/// fade behaviour and fade durations. Backed by [SharedPreferences].
class AudioSettings {
  AudioSettings._();
  static final AudioSettings instance = AudioSettings._();

  /// Multiplier applied on top of each channel's own volume (0..1).
  final ValueNotifier<double> masterVolume = ValueNotifier(1.0);

  /// Master switch for fade-in / fade-out transitions.
  final ValueNotifier<bool> fadeEnabled = ValueNotifier(true);

  /// When enabled (and [fadeEnabled]), track changes overlap the two players
  /// instead of cutting before fading in.
  final ValueNotifier<bool> crossfadeEnabled = ValueNotifier(true);

  /// Duration of the short fade used for pause / resume / play (milliseconds).
  final ValueNotifier<int> shortFadeMs = ValueNotifier(500);

  /// Duration of the longer fade used for track changes (milliseconds).
  final ValueNotifier<int> longFadeMs = ValueNotifier(2000);

  Duration get shortFade => Duration(milliseconds: shortFadeMs.value);
  Duration get longFade => Duration(milliseconds: longFadeMs.value);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    masterVolume.value = p.getDouble('master_volume') ?? 1.0;
    fadeEnabled.value = p.getBool('fade_enabled') ?? true;
    crossfadeEnabled.value = p.getBool('crossfade_enabled') ?? true;
    shortFadeMs.value = p.getInt('short_fade_ms') ?? 500;
    longFadeMs.value = p.getInt('long_fade_ms') ?? 2000;
  }

  Future<void> setMasterVolume(double v) async {
    masterVolume.value = v;
    (await SharedPreferences.getInstance()).setDouble('master_volume', v);
  }

  Future<void> setFadeEnabled(bool v) async {
    fadeEnabled.value = v;
    (await SharedPreferences.getInstance()).setBool('fade_enabled', v);
  }

  Future<void> setCrossfadeEnabled(bool v) async {
    crossfadeEnabled.value = v;
    (await SharedPreferences.getInstance()).setBool('crossfade_enabled', v);
  }

  Future<void> setShortFadeMs(int v) async {
    shortFadeMs.value = v;
    (await SharedPreferences.getInstance()).setInt('short_fade_ms', v);
  }

  Future<void> setLongFadeMs(int v) async {
    longFadeMs.value = v;
    (await SharedPreferences.getInstance()).setInt('long_fade_ms', v);
  }
}
