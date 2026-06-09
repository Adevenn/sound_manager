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

  static Future<void> _saveAll(List<Scene> scenes) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(scenes.map((s) => s.toJson()).toList()));
  }

  /// Adds [scene], replacing any existing scene with the same name.
  static Future<void> add(Scene scene) async {
    final scenes = await list()
      ..removeWhere((s) => s.name == scene.name)
      ..add(scene);
    await _saveAll(scenes);
  }

  static Future<void> delete(String name) async {
    final scenes = await list()..removeWhere((s) => s.name == name);
    await _saveAll(scenes);
  }
}
