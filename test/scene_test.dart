import 'package:flutter_test/flutter_test.dart';
import 'package:sound_manager/model.dart';

void main() {
  group('Scene serialization', () {
    test('toJson/fromJson round-trips playlists and volumes', () {
      final scene = Scene(
        name: 'Combat',
        playlists: {'ambiance': 'Cave', 'music': 'Battle', 'effect': 'Hits'},
        volumes: {'ambiance': 0.5, 'music': 1.0, 'effect': 0.8},
      );

      final restored = Scene.fromJson(scene.toJson());
      expect(restored.name, 'Combat');
      expect(restored.playlists['music'], 'Battle');
      expect(restored.volumes['ambiance'], 0.5);
      expect(restored.volumes['effect'], 0.8);
    });

    test('tolerates missing maps in legacy json', () {
      final restored = Scene.fromJson({'name': 'Empty'});
      expect(restored.name, 'Empty');
      expect(restored.playlists, isEmpty);
      expect(restored.volumes, isEmpty);
    });

    test('reads integer volumes as doubles', () {
      final restored = Scene.fromJson({
        'name': 'Mixed',
        'playlists': {'music': 'X'},
        'volumes': {'music': 1},
      });
      expect(restored.volumes['music'], 1.0);
    });
  });
}
