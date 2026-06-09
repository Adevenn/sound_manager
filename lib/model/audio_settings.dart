import 'package:flutter/foundation.dart';
import 'package:sound_manager/model/prefs.dart';

/// Global, app-wide audio settings (shared by every channel): master volume,
/// fade behaviour and fade durations. Backed by the shared [Prefs] instance.
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

  void load() {
    final p = Prefs.instance;
    masterVolume.value = p.getDouble('master_volume') ?? 1.0;
    fadeEnabled.value = p.getBool('fade_enabled') ?? true;
    crossfadeEnabled.value = p.getBool('crossfade_enabled') ?? true;
    shortFadeMs.value = p.getInt('short_fade_ms') ?? 500;
    longFadeMs.value = p.getInt('long_fade_ms') ?? 2000;
  }

  void setMasterVolume(double v) {
    masterVolume.value = v;
    Prefs.instance.setDouble('master_volume', v);
  }

  void setFadeEnabled(bool v) {
    fadeEnabled.value = v;
    Prefs.instance.setBool('fade_enabled', v);
  }

  void setCrossfadeEnabled(bool v) {
    crossfadeEnabled.value = v;
    Prefs.instance.setBool('crossfade_enabled', v);
  }

  void setShortFadeMs(int v) {
    shortFadeMs.value = v;
    Prefs.instance.setInt('short_fade_ms', v);
  }

  void setLongFadeMs(int v) {
    longFadeMs.value = v;
    Prefs.instance.setInt('long_fade_ms', v);
  }
}
