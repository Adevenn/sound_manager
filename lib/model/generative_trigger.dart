import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sound_manager/model/audio_player_manager.dart';
import 'package:sound_manager/model/audio_settings.dart';

/// "Generative ambiance" mode: while enabled, fires a random effect from the
/// effects channel (only those flagged [Soundtrack.generative]) after a random
/// delay between [AudioSettings.genMinSec] and [AudioSettings.genMaxSec], then
/// schedules the next one — endlessly, until disabled.
///
/// Great for sparse, unpredictable background events (distant howls, thunder,
/// a creaking door) that make a scene feel alive without the GM touching a key.
class GenerativeTrigger {
  final AudioPlayerManager effectPlayer;
  GenerativeTrigger(this.effectPlayer);

  final ValueNotifier<bool> enabled = ValueNotifier(false);

  /// Seconds until the next fire, for an optional countdown in the UI.
  final ValueNotifier<int> nextInSeconds = ValueNotifier(0);

  Timer? _timer;
  Timer? _tick;
  final Random _rng = Random();

  /// Effects eligible to be triggered (flagged generative).
  int get eligibleCount =>
      effectPlayer.tracks.where((t) => t.generative).length;

  void toggle() => enabled.value ? stop() : start();

  void start() {
    if (enabled.value) return;
    enabled.value = true;
    _schedule();
  }

  void stop() {
    enabled.value = false;
    _timer?.cancel();
    _tick?.cancel();
    nextInSeconds.value = 0;
  }

  void _schedule() {
    final lo = max(1, AudioSettings.instance.genMinSec.value);
    final hi = max(lo, AudioSettings.instance.genMaxSec.value);
    final secs = lo + _rng.nextInt(hi - lo + 1);
    nextInSeconds.value = secs;
    _timer?.cancel();
    _timer = Timer(Duration(seconds: secs), _fire);
    // Drive a 1 Hz countdown for the UI badge.
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (nextInSeconds.value > 0) nextInSeconds.value--;
    });
  }

  void _fire() {
    if (!enabled.value) return;
    final pool = effectPlayer.tracks.where((t) => t.generative).toList();
    if (pool.isNotEmpty) {
      effectPlayer.playEffect(pool[_rng.nextInt(pool.length)]);
    }
    _schedule(); // queue the next event regardless (pool may fill up later)
  }

  void dispose() {
    _timer?.cancel();
    _tick?.cancel();
    enabled.dispose();
    nextInSeconds.dispose();
  }
}
