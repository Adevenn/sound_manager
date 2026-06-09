import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sound_manager/model/app_directories.dart';
import 'package:sound_manager/model/playlist.dart';

/// Reads and writes [Playlist]s as `<name>.json` files. This is the only place
/// that touches the disk for playlists, so the [Playlist] model itself stays a
/// pure in-memory object (easy to unit-test). All I/O is asynchronous to keep
/// it off the UI thread.
class PlaylistRepository {
  PlaylistRepository._();

  static Future<File> _fileFor(String name) async =>
      File(p.join((await AppDirectories.playlists()).path, '$name.json'));

  /// Loads the playlist stored under [name]. Throws if the file is missing or
  /// malformed, so callers can fall back to an empty playlist.
  static Future<Playlist> load(String name) async {
    final file = await _fileFor(name);
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return Playlist.fromJson(json);
  }

  /// Writes [playlist] to `<playlist.name>.json`.
  static Future<void> save(Playlist playlist) async {
    final file = await _fileFor(playlist.name);
    await file.writeAsString(jsonEncode(playlist.toJson()));
  }

  /// Renames [playlist] to [newName] and saves it under the new file name
  /// (used by "save as").
  static Future<void> saveAs(Playlist playlist, String newName) async {
    playlist.rename(newName);
    await save(playlist);
  }

  /// Names (without extension) of every playlist saved on disk, sorted.
  static Future<List<String>> listAll() async {
    final dir = await AppDirectories.playlists();
    final entries = await dir.list().toList();
    return entries
        .where((f) => p.extension(f.path).toLowerCase() == '.json')
        .map((f) => p.basenameWithoutExtension(f.path))
        .toList()
      ..sort();
  }

  /// Deletes the playlist file named [name] if it exists.
  static Future<void> delete(String name) async {
    final file = await _fileFor(name);
    if (await file.exists()) await file.delete();
  }
}
