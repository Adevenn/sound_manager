import 'package:flutter/foundation.dart';
import 'package:sound_manager/model/audio_settings.dart';

/// Runtime glue for "auto-duck": while one or more effects are sounding, the
/// ambiance and music channels drop to [AudioSettings.duckAmount] of their
/// normal volume, then ramp back up once the board goes quiet.
///
/// The effects channel reports whether any effect is active via
/// [setEffectsActive]; the music/ambiance channels listen to [factor] and ramp
/// their live volume toward it. Deriving from a boolean "any active" state
/// (rather than counting) keeps it correct even when pooled players are
/// recycled without emitting a completion event.
class DuckController {
  DuckController._();
  static final DuckController instance = DuckController._();

  /// Volume multiplier the ducked channels should currently apply (1.0 = no
  /// ducking).
  final ValueNotifier<double> factor = ValueNotifier(1.0);

  void setEffectsActive(bool active) {
    final settings = AudioSettings.instance;
    final shouldDuck = settings.duckEnabled.value && active;
    factor.value = shouldDuck ? settings.duckAmount.value.clamp(0.0, 1.0) : 1.0;
  }
}
