import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sound_manager/model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs.init();
    CampaignManager.instance.current.value = CampaignManager.defaultCampaign;
  });

  tearDown(() {
    CampaignManager.instance.current.value = CampaignManager.defaultCampaign;
  });

  group('Campaign-scoped settings', () {
    test('per-channel settings are isolated between campaigns', () async {
      // Default campaign keeps the legacy (unprefixed) key.
      await UserSettings.setPlayerVolume(PlayerType.music, 0.5);

      CampaignManager.instance.current.value = 'Other';
      // A fresh campaign starts from defaults.
      expect(UserSettings.getPlayerVolume(PlayerType.music), 1.0);
      await UserSettings.setPlayerVolume(PlayerType.music, 0.8);

      CampaignManager.instance.current.value = CampaignManager.defaultCampaign;
      expect(UserSettings.getPlayerVolume(PlayerType.music), 0.5);

      CampaignManager.instance.current.value = 'Other';
      expect(UserSettings.getPlayerVolume(PlayerType.music), 0.8);
    });

    test('Default campaign reads pre-existing legacy keys', () async {
      SharedPreferences.setMockInitialValues({'ambiance_volume': 0.33});
      await Prefs.init();
      expect(UserSettings.getPlayerVolume(PlayerType.ambiance), 0.33);
    });

    test('campaign names are sanitized for the filesystem', () {
      expect(CampaignManager.sanitize('My: "Game"?'), 'My_ _Game__');
      expect(
        CampaignManager.sanitize('  Curse of Strahd  '),
        'Curse of Strahd',
      );
      expect(CampaignManager.sanitize('a/b\\c'), 'a_b_c');
    });
  });

  group('Soundtrack URL support', () {
    test('url soundtrack round-trips with its title', () {
      final t = Soundtrack(
        'https://example.com/stream.mp3',
        SoundtrackType.url,
        title: 'Radio',
      );
      final restored = Soundtrack.fromJson(t.toJson());
      expect(restored.type, SoundtrackType.url);
      expect(restored.source, 'https://example.com/stream.mp3');
      expect(restored.name, 'Radio');
    });

    test('url name falls back to the URL basename without query', () {
      final t = Soundtrack(
        'https://host/path/wind.ogg?token=abc',
        SoundtrackType.url,
      );
      expect(t.name, 'wind');
    });

    test('url sources are always considered present', () async {
      final t = Soundtrack('https://host/x.mp3', SoundtrackType.url);
      expect(await t.exists(), isTrue);
    });

    test('generative flag round-trips', () {
      final t = Soundtrack('a.mp3', SoundtrackType.local, generative: true);
      expect(Soundtrack.fromJson(t.toJson()).generative, isTrue);
    });
  });
}
