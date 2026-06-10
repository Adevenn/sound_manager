import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sound_manager/model/app_directories.dart';
import 'package:sound_manager/model/scene.dart';

/// Persists the list of [Scene]s in a single `scenes.json` file. All I/O is
/// asynchronous so it never blocks the UI thread.
class SceneManager {
  SceneManager._();

  static Future<File> _file() async =>
      File(p.join((await AppDirectories.data()).path, 'scenes.json'));

  static Future<List<Scene>> list() async {
    final file = await _file();
    if (!await file.exists()) return [];
    try {
      final json = jsonDecode(await file.readAsString()) as List;
      return json.map((e) => Scene.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Atomic write (temp file + rename) so a crash mid-write can never corrupt
  /// the whole scene collection.
  static Future<void> _saveAll(List<Scene> scenes) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode(scenes.map((s) => s.toJson()).toList()),
      flush: true,
    );
    await tmp.rename(file.path);
  }

  /// Adds [scene], replacing any existing scene with the same name.
  static Future<void> add(Scene scene) async {
    final scenes =
        await list()
          ..removeWhere((s) => s.name == scene.name)
          ..add(scene);
    await _saveAll(scenes);
  }

  static Future<void> delete(String name) async {
    final scenes =
        await list()
          ..removeWhere((s) => s.name == name);
    await _saveAll(scenes);
  }

  /// Renames scene [oldName] to [newName] (no-op if the new name is empty or
  /// already taken).
  static Future<void> rename(String oldName, String newName) async {
    final clean = newName.trim();
    if (clean.isEmpty) return;
    final scenes = await list();
    if (scenes.any((s) => s.name == clean)) return;
    final index = scenes.indexWhere((s) => s.name == oldName);
    if (index == -1) return;
    scenes[index].name = clean;
    await _saveAll(scenes);
  }

  /// Duplicates scene [name] under `<name> (copy)` (uniquified).
  static Future<void> duplicate(String name) async {
    final scenes = await list();
    final index = scenes.indexWhere((s) => s.name == name);
    if (index == -1) return;
    final scene = scenes[index];
    final existing = scenes.map((s) => s.name).toSet();
    var copy = '$name (copy)';
    var n = 2;
    while (existing.contains(copy)) {
      copy = '$name (copy $n)';
      n++;
    }
    scenes.add(
      Scene(
        name: copy,
        playlists: Map.of(scene.playlists),
        volumes: Map.of(scene.volumes),
      ),
    );
    await _saveAll(scenes);
  }
}
