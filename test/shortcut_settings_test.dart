import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_manager/model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    ShortcutSettings.instance.resetDefaults();
  });

  group('ShortcutSettings conflicts', () {
    test('binding an effect key steals it from another effect slot', () {
      final s = ShortcutSettings.instance;
      expect(s.setEffectKey(0, LogicalKeyboardKey.keyA), isTrue);
      expect(s.setEffectKey(1, LogicalKeyboardKey.keyA), isTrue);
      expect(s.effectKeys[1], LogicalKeyboardKey.keyA);
      expect(s.effectKeys[0], isNull);
    });

    test('an effect key cannot take the global play/pause key', () {
      final s = ShortcutSettings.instance;
      s.setPlayPauseAll(LogicalKeyboardKey.keyP);
      expect(s.setEffectKey(0, LogicalKeyboardKey.keyP), isFalse);
      expect(s.effectKeys[0], isNot(LogicalKeyboardKey.keyP));
      expect(s.playPauseAll, LogicalKeyboardKey.keyP);
    });

    test('play/pause steals its new key from an effect slot', () {
      final s = ShortcutSettings.instance;
      s.setEffectKey(2, LogicalKeyboardKey.keyB);
      s.setPlayPauseAll(LogicalKeyboardKey.keyB);
      expect(s.playPauseAll, LogicalKeyboardKey.keyB);
      expect(s.effectKeys[2], isNull);
    });

    test('bindings survive a reload from prefs', () {
      final s = ShortcutSettings.instance;
      s.setPlayPauseAll(LogicalKeyboardKey.keyM);
      s.setEffectKey(0, LogicalKeyboardKey.keyA);
      s.setEffectKey(1, null); // deliberately cleared slot
      s.load();
      expect(s.playPauseAll, LogicalKeyboardKey.keyM);
      expect(s.effectKeys[0], LogicalKeyboardKey.keyA);
      expect(s.effectKeys[1], isNull);
    });
  });
}
