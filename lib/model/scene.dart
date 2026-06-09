import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A saved combination of the three channels (which playlist + which volume),
/// so a GM can switch the whole soundscape in one click (e.g. "Tavern",
/// "Combat", "Dungeon").
class Scene {
  String name;

  /// channel type name (`ambiance`/`music`/`effect`) -> playlist name.
  final Map<String, String> playlists;

  /// channel type name -> volume (0..1).
  final Map<String, double> volumes;

  Scene({required this.name, required this.playlists, required this.volumes});

  Scene.fromJson(Map<String, dynamic> json)
    : name = json['name'],
      playlists = Map<String, String>.from(json['playlists'] ?? {}),
      volumes = (json['volumes'] as Map?)?.map(
            (k, v) => MapEntry(k as String, (v as num).toDouble()),
          ) ??
          {};

  Map<String, dynamic> toJson() => {
    'name': name,
    'playlists': playlists,
    'volumes': volumes,
  };
}

/// Persists the list of [Scene]s in a single `scenes.json` file.
class SceneManager {
  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    final data = await Directory('${dir.path}/Data').create();
    return File('${data.path}/scenes.json');
  }

  static Future<List<Scene>> list() async {
    final file = await _file();
    if (!file.existsSync()) return [];
    try {
      final json = jsonDecode(file.readAsStringSync()) as List;
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
