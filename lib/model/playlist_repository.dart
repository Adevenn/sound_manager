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

  /// Strips characters that are forbidden in file names (notably on Windows:
  /// `\ / : * ? " < > |`) so any user-typed playlist name can be saved.
  static String _safeFileName(String name) =>
      name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();

  static Future<File> _fileFor(String name) async => File(
    p.join(
      (await AppDirectories.playlists()).path,
      '${_safeFileName(name)}.json',
    ),
  );

  /// Loads the playlist stored under [name]. Throws if the file is missing or
  /// malformed, so callers can fall back to an empty playlist.
  static Future<Playlist> load(String name) async {
    final file = await _fileFor(name);
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return Playlist.fromJson(json);
  }

  /// Writes [playlist] to `<playlist.name>.json`. The write is atomic (temp
  /// file + rename) so a crash mid-write can never corrupt an existing file.
  static Future<void> save(Playlist playlist) async {
    final file = await _fileFor(playlist.name);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(playlist.toJson()), flush: true);
    await tmp.rename(file.path);
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

  /// Renames the saved playlist [oldName] to [newName] (also updates the id-less
  /// name field inside the file). No-op if the source is missing.
  static Future<void> rename(String oldName, String newName) async {
    final clean = _safeFileName(newName);
    if (clean.isEmpty || clean == _safeFileName(oldName)) return;
    final Playlist playlist;
    try {
      playlist = await load(oldName);
    } catch (_) {
      return;
    }
    playlist.rename(clean);
    await save(playlist);
    await delete(oldName);
  }

  /// Saves a copy of [name] under `<name> (copy)` (uniquified) and returns the
  /// new name, or null if the source could not be read.
  static Future<String?> duplicate(String name) async {
    final Playlist source;
    try {
      source = await load(name);
    } catch (_) {
      return null;
    }
    final existing = (await listAll()).toSet();
    var copy = '$name (copy)';
    var n = 2;
    while (existing.contains(_safeFileName(copy))) {
      copy = '$name (copy $n)';
      n++;
    }
    source.rename(copy);
    await save(source);
    return copy;
  }
}
