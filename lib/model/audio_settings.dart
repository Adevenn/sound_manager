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

  /// Duration of the cross-fade between two whole scenes (milliseconds).
  final ValueNotifier<int> sceneFadeMs = ValueNotifier(2500);

  /// When enabled, the ambiance + music channels duck (drop in volume) while
  /// any effect is sounding, then ramp back up.
  final ValueNotifier<bool> duckEnabled = ValueNotifier(false);

  /// Fraction the ducked channels are reduced *to* while an effect plays
  /// (0.4 => 40% of their normal volume). 1.0 means no ducking.
  final ValueNotifier<double> duckAmount = ValueNotifier(0.4);

  /// Generative ambiance mode: bounds (seconds) of the random delay between two
  /// automatic effect triggers.
  final ValueNotifier<int> genMinSec = ValueNotifier(30);
  final ValueNotifier<int> genMaxSec = ValueNotifier(120);

  Duration get shortFade => Duration(milliseconds: shortFadeMs.value);
  Duration get longFade => Duration(milliseconds: longFadeMs.value);
  Duration get sceneFade => Duration(milliseconds: sceneFadeMs.value);

  void load() {
    final p = Prefs.instance;
    masterVolume.value = p.getDouble('master_volume') ?? 1.0;
    fadeEnabled.value = p.getBool('fade_enabled') ?? true;
    crossfadeEnabled.value = p.getBool('crossfade_enabled') ?? true;
    shortFadeMs.value = p.getInt('short_fade_ms') ?? 500;
    longFadeMs.value = p.getInt('long_fade_ms') ?? 2000;
    sceneFadeMs.value = p.getInt('scene_fade_ms') ?? 2500;
    duckEnabled.value = p.getBool('duck_enabled') ?? false;
    duckAmount.value = p.getDouble('duck_amount') ?? 0.4;
    genMinSec.value = p.getInt('gen_min_sec') ?? 30;
    genMaxSec.value = p.getInt('gen_max_sec') ?? 120;
  }

  void setGenMinSec(int v) {
    genMinSec.value = v;
    Prefs.instance.setInt('gen_min_sec', v);
  }

  void setGenMaxSec(int v) {
    genMaxSec.value = v;
    Prefs.instance.setInt('gen_max_sec', v);
  }

  void setSceneFadeMs(int v) {
    sceneFadeMs.value = v;
    Prefs.instance.setInt('scene_fade_ms', v);
  }

  void setDuckEnabled(bool v) {
    duckEnabled.value = v;
    Prefs.instance.setBool('duck_enabled', v);
  }

  void setDuckAmount(double v) {
    duckAmount.value = v;
    Prefs.instance.setDouble('duck_amount', v);
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
