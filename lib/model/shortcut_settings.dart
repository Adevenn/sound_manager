import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sound_manager/model/player_type.enum.dart';
import 'package:sound_manager/model/prefs.dart';

/// User-rebindable keyboard shortcuts, backed by the shared [Prefs] instance.
///
/// Action groups:
/// - [playPauseAll]: global pause/resume for the ambiance + music channels.
/// - [effectKeys]: one key per soundboard slot (slot `i` triggers the i-th
///   effect). A `null` slot means "no key bound".
/// - [channelPause] / [channelNext]: per-channel pause and skip, for ambiance
///   and music independently (all `null` by default).
///
/// A given key can only drive one action: assigning it steals it from any other
/// (nullable) binding. The always-bound [playPauseAll] key is reserved and
/// cannot be taken by another binding.
///
/// Keys are persisted by their stable [LogicalKeyboardKey.keyId]. The
/// [revision] notifier lets the live UI rebuild its bindings as soon as the
/// user reassigns a key.
class ShortcutSettings {
  ShortcutSettings._();
  static final ShortcutSettings instance = ShortcutSettings._();

  /// Number of bindable soundboard slots (effects 1..9).
  static const int effectSlots = 9;

  /// Channels that support per-channel pause/skip shortcuts.
  static const List<PlayerType> shortcutChannels = [
    PlayerType.ambiance,
    PlayerType.music,
  ];

  static const _kPlayPause = 'sc_play_pause';
  static const _kEffectPrefix = 'sc_effect_';
  static const _kPausePrefix = 'sc_pause_';
  static const _kNextPrefix = 'sc_next_';
  // Sentinel persisted for a deliberately-cleared slot (no key id is 0).
  static const int _unbound = 0;

  LogicalKeyboardKey playPauseAll = LogicalKeyboardKey.space;

  final List<LogicalKeyboardKey?> effectKeys = List.generate(
    effectSlots,
    (i) => _defaultDigits[i],
  );

  final Map<PlayerType, LogicalKeyboardKey?> channelPause = {
    for (final c in shortcutChannels) c: null,
  };
  final Map<PlayerType, LogicalKeyboardKey?> channelNext = {
    for (final c in shortcutChannels) c: null,
  };

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

  void load() {
    final p = Prefs.instance;
    final pp = p.getInt(_kPlayPause);
    if (pp != null) playPauseAll = LogicalKeyboardKey(pp);
    for (var i = 0; i < effectSlots; i++) {
      final v = p.getInt('$_kEffectPrefix$i');
      if (v != null) {
        effectKeys[i] = v == _unbound ? null : LogicalKeyboardKey(v);
      }
    }
    for (final c in shortcutChannels) {
      final pause = p.getInt('$_kPausePrefix${c.name}');
      if (pause != null) {
        channelPause[c] = pause == _unbound ? null : LogicalKeyboardKey(pause);
      }
      final next = p.getInt('$_kNextPrefix${c.name}');
      if (next != null) {
        channelNext[c] = next == _unbound ? null : LogicalKeyboardKey(next);
      }
    }
  }

  // -- Conflict handling ----------------------------------------------------

  /// Removes [key] from every *nullable* binding (effects + per-channel),
  /// persisting each cleared slot. The always-bound [playPauseAll] is left
  /// untouched (it is reserved).
  void _clearKeyFromNullable(LogicalKeyboardKey key) {
    for (var i = 0; i < effectSlots; i++) {
      if (effectKeys[i] == key) {
        effectKeys[i] = null;
        Prefs.instance.setInt('$_kEffectPrefix$i', _unbound);
      }
    }
    for (final c in shortcutChannels) {
      if (channelPause[c] == key) {
        channelPause[c] = null;
        Prefs.instance.setInt('$_kPausePrefix${c.name}', _unbound);
      }
      if (channelNext[c] == key) {
        channelNext[c] = null;
        Prefs.instance.setInt('$_kNextPrefix${c.name}', _unbound);
      }
    }
  }

  void setPlayPauseAll(LogicalKeyboardKey key) {
    _clearKeyFromNullable(key); // steal it from any effect/channel slot
    playPauseAll = key;
    Prefs.instance.setInt(_kPlayPause, key.keyId);
    revision.value++;
  }

  /// Binds [key] to effect [slot]. Returns false (no change) when [key] is the
  /// reserved play/pause key; a key used elsewhere is stolen from it.
  bool setEffectKey(int slot, LogicalKeyboardKey? key) {
    if (slot < 0 || slot >= effectSlots) return false;
    if (key != null) {
      if (key == playPauseAll) return false;
      _clearKeyFromNullable(key);
    }
    effectKeys[slot] = key;
    Prefs.instance.setInt('$_kEffectPrefix$slot', key?.keyId ?? _unbound);
    revision.value++;
    return true;
  }

  bool setChannelPause(PlayerType channel, LogicalKeyboardKey? key) =>
      _setChannelKey(channelPause, _kPausePrefix, channel, key);

  bool setChannelNext(PlayerType channel, LogicalKeyboardKey? key) =>
      _setChannelKey(channelNext, _kNextPrefix, channel, key);

  bool _setChannelKey(
    Map<PlayerType, LogicalKeyboardKey?> map,
    String prefix,
    PlayerType channel,
    LogicalKeyboardKey? key,
  ) {
    if (!map.containsKey(channel)) return false;
    if (key != null) {
      if (key == playPauseAll) return false;
      _clearKeyFromNullable(key);
    }
    map[channel] = key;
    Prefs.instance.setInt('$prefix${channel.name}', key?.keyId ?? _unbound);
    revision.value++;
    return true;
  }

  void resetDefaults() {
    playPauseAll = LogicalKeyboardKey.space;
    for (var i = 0; i < effectSlots; i++) {
      effectKeys[i] = _defaultDigits[i];
    }
    for (final c in shortcutChannels) {
      channelPause[c] = null;
      channelNext[c] = null;
    }
    final p = Prefs.instance;
    p.remove(_kPlayPause);
    for (var i = 0; i < effectSlots; i++) {
      p.remove('$_kEffectPrefix$i');
    }
    for (final c in shortcutChannels) {
      p.remove('$_kPausePrefix${c.name}');
      p.remove('$_kNextPrefix${c.name}');
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
