import 'package:flutter_test/flutter_test.dart';
import 'package:sound_manager/model.dart';

/// Builds a playlist of [count] dummy local tracks, selection on track 0.
Playlist _playlistOf(int count) {
  final pl = Playlist.empty('test');
  for (var i = 0; i < count; i++) {
    pl.addSoundtrack('track_$i.mp3');
  }
  return pl;
}

void main() {
  group('Playlist navigation', () {
    test('nextTrack advances and stops at the end when not looping', () {
      final pl = _playlistOf(3);
      expect(pl.trackIndex.value, 0);
      expect(pl.nextTrack(), isTrue);
      expect(pl.trackIndex.value, 1);
      expect(pl.nextTrack(), isTrue);
      expect(pl.trackIndex.value, 2);
      // Last track + LoopMode.none -> nothing more to play.
      expect(pl.nextTrack(), isFalse);
      expect(pl.trackIndex.value, 2);
    });

    test('nextTrack wraps to the start under LoopMode.all', () {
      final pl = _playlistOf(3);
      pl.changeTrack(2);
      pl.loopMode.value = LoopMode.all;
      expect(pl.nextTrack(), isTrue);
      expect(pl.trackIndex.value, 0);
    });

    test('previousTrack decrements but never goes below 0', () {
      final pl = _playlistOf(3);
      pl.changeTrack(1);
      pl.previousTrack();
      expect(pl.trackIndex.value, 0);
      pl.previousTrack();
      expect(pl.trackIndex.value, 0);
    });
  });

  group('Playlist editing', () {
    test('removeTrack clamps the current index', () {
      final pl = _playlistOf(3);
      pl.changeTrack(2);
      pl.removeTrack(2);
      expect(pl.length, 2);
      expect(pl.trackIndex.value, 1);
    });

    test('removeTrack down to empty resets index to 0', () {
      final pl = _playlistOf(1);
      pl.removeTrack(0);
      expect(pl.isEmpty, isTrue);
      expect(pl.trackIndex.value, 0);
      expect(pl.actualSoundtrack, isNull);
    });

    test('reorderTrack moves the last track to the front, keeping selection', () {
      final pl = _playlistOf(3); // track_0 selected
      final selected = pl.actualSoundtrack;
      pl.reorderTrack(2, 0);
      expect(pl.actualSoundtrack, same(selected));
      expect(pl.trackIndex.value, 1);
    });

    test('reorderTrack moves an item down (post-removal index convention)', () {
      final pl = _playlistOf(3); // [t0, t1, t2], t0 selected
      final selected = pl.actualSoundtrack; // t0
      // onReorderItem passes the destination index *after* removal: dragging
      // t0 to the end yields newIndex == 2 (not 3).
      pl.reorderTrack(0, 2);
      expect(pl.tracks.last, same(selected));
      expect(pl.actualSoundtrack, same(selected));
      expect(pl.trackIndex.value, 2);
    });

    test('actualSoundtrack clamps a stale index', () {
      final pl = _playlistOf(3);
      pl.changeTrack(2);
      pl.removeTrack(0); // index now refers past the end before clamping
      expect(pl.actualSoundtrack, isNotNull);
    });
  });

  group('Loop mode', () {
    test('cycleLoop goes none -> all -> one -> none', () {
      final pl = _playlistOf(1);
      expect(pl.loopMode.value, LoopMode.none);
      pl.cycleLoop();
      expect(pl.loopMode.value, LoopMode.all);
      pl.cycleLoop();
      expect(pl.loopMode.value, LoopMode.one);
      pl.cycleLoop();
      expect(pl.loopMode.value, LoopMode.none);
    });
  });

  group('Shuffle bag', () {
    test('plays every other track once then stops when not looping', () {
      final pl = _playlistOf(4);
      pl.changeTrack(0);
      pl.toggleShuffle();
      expect(pl.shuffle.value, isTrue);

      final visited = <int>{0};
      while (pl.nextTrack()) {
        visited.add(pl.trackIndex.value);
      }
      // The whole bag (every index) is visited exactly once.
      expect(visited, {0, 1, 2, 3});
      // Bag exhausted and not looping -> no more tracks.
      expect(pl.nextTrack(), isFalse);
    });

    test('reshuffles forever under LoopMode.all', () {
      final pl = _playlistOf(3);
      pl.loopMode.value = LoopMode.all;
      pl.toggleShuffle();
      // Far more picks than tracks: must never run out.
      for (var i = 0; i < 20; i++) {
        expect(pl.nextTrack(), isTrue);
      }
    });

    test('single track loops only under LoopMode.all', () {
      final pl = _playlistOf(1);
      pl.toggleShuffle();
      expect(pl.nextTrack(), isFalse);
      pl.loopMode.value = LoopMode.all;
      expect(pl.nextTrack(), isTrue);
    });
  });

  group('Serialization', () {
    test('toJson/fromJson round-trips every field', () {
      final pl = _playlistOf(2);
      pl.changeTrack(1);
      pl.loopMode.value = LoopMode.one;
      pl.shuffle.value = true;

      final restored = Playlist.fromJson(pl.toJson());
      expect(restored.id, pl.id);
      expect(restored.name, pl.name);
      expect(restored.length, 2);
      expect(restored.trackIndex.value, 1);
      expect(restored.loopMode.value, LoopMode.one);
      expect(restored.shuffle.value, isTrue);
      expect(restored.compare(pl), isTrue);
    });

    test('legacy "loop": true maps to LoopMode.all', () {
      final json = {
        'id': 'abc',
        'name': 'old',
        'sounds': <dynamic>[],
        'index': 0,
        'loop': true,
      };
      final pl = Playlist.fromJson(json);
      expect(pl.loopMode.value, LoopMode.all);
    });
  });
}
