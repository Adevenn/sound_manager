import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-rebindable keyboard shortcuts, backed by [SharedPreferences].
///
/// Two groups of actions:
/// - [playPauseAll]: global pause/resume for the ambiance + music channels.
/// - [effectKeys]: one key per soundboard slot (slot `i` triggers the
///   `i`-th effect). A `null` slot means "no key bound".
///
/// Keys are persisted by their stable [LogicalKeyboardKey.keyId]. The
/// [revision] notifier lets the live UI (the global shortcut handler) rebuild
/// its bindings as soon as the user reassigns a key.
class ShortcutSettings {
  ShortcutSettings._();
  static final ShortcutSettings instance = ShortcutSettings._();

  /// Number of bindable soundboard slots (effects 1..9).
  static const int effectSlots = 9;

  static const _kPlayPause = 'sc_play_pause';
  static const _kEffectPrefix = 'sc_effect_';
  // Sentinel persisted for a deliberately-cleared slot (no key id is 0).
  static const int _unbound = 0;

  LogicalKeyboardKey playPauseAll = LogicalKeyboardKey.space;

  final List<LogicalKeyboardKey?> effectKeys = List.generate(
    effectSlots,
    (i) => _defaultDigits[i],
  );

  static const List<LogicalKeyboardKey> _defaultDigits = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  ];

  /// Bumped whenever a binding changes so listeners can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final pp = p.getInt(_kPlayPause);
    if (pp != null) playPauseAll = LogicalKeyboardKey(pp);
    for (var i = 0; i < effectSlots; i++) {
      final v = p.getInt('$_kEffectPrefix$i');
      if (v != null) {
        effectKeys[i] = v == _unbound ? null : LogicalKeyboardKey(v);
      }
    }
  }

  Future<void> setPlayPauseAll(LogicalKeyboardKey key) async {
    playPauseAll = key;
    (await SharedPreferences.getInstance()).setInt(_kPlayPause, key.keyId);
    revision.value++;
  }

  Future<void> setEffectKey(int slot, LogicalKeyboardKey? key) async {
    if (slot < 0 || slot >= effectSlots) return;
    effectKeys[slot] = key;
    (await SharedPreferences.getInstance()).setInt(
      '$_kEffectPrefix$slot',
      key?.keyId ?? _unbound,
    );
    revision.value++;
  }

  Future<void> resetDefaults() async {
    playPauseAll = LogicalKeyboardKey.space;
    for (var i = 0; i < effectSlots; i++) {
      effectKeys[i] = _defaultDigits[i];
    }
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPlayPause);
    for (var i = 0; i < effectSlots; i++) {
      await p.remove('$_kEffectPrefix$i');
    }
    revision.value++;
  }

  /// Modifier keys can't stand alone as a binding.
  static final Set<LogicalKeyboardKey> _modifiers = {
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  };

  static bool isModifier(LogicalKeyboardKey k) => _modifiers.contains(k);

  /// Human-readable label for a key (the raw [LogicalKeyboardKey.keyLabel] is
  /// empty or a bare space for some keys).
  static String labelFor(LogicalKeyboardKey? k) {
    if (k == null) return '—';
    if (k == LogicalKeyboardKey.space) return 'Space';
    if (k == LogicalKeyboardKey.enter) return 'Enter';
    if (k == LogicalKeyboardKey.tab) return 'Tab';
    final label = k.keyLabel.trim();
    if (label.isNotEmpty) return label.toUpperCase();
    return 'Key ${k.keyId}';
  }
}
